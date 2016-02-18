package GRNOC::NetSage::Anonymizer::FlowAnonymizer;

use Moo;

use GRNOC::Log;
use GRNOC::Config;

use Net::AMQP::RabbitMQ;
use JSON::XS;
use Math::Round qw( nlowmult nhimult );
use List::MoreUtils qw( natatime );
use Try::Tiny;

use Data::Dumper;

### constants ###

use constant QUEUE_PREFETCH_COUNT => 20;
use constant QUEUE_FETCH_TIMEOUT => 10 * 1000;
use constant RECONNECT_TIMEOUT => 10;
use constant RAW_FLOWS_QUEUE_CHANNEL => 1;
use constant ANONYMIZED_FLOWS_QUEUE_CHANNEL => 2;

### required attributes ###

has config_file => ( is => 'ro',
                required => 1 );

has logging_file => ( is => 'ro',
                      required => 1 );

### internal attributes ###

has logger => ( is => 'rwp' );

has config => ( is => 'rwp' );

has is_running => ( is => 'rwp',
                    default => 0 );

has rabbit => ( is => 'rwp' );

has json => ( is => 'rwp' );

has json_data => ( is => 'rwp' );

### constructor builder ###

sub BUILD {

    my ( $self ) = @_;

    # create and store logger object
    my $grnoc_log = GRNOC::Log->new( config => $self->logging_file );
    my $logger = GRNOC::Log->get_logger();

    $self->_set_logger( $logger );

    # create and store config object
    my $config = GRNOC::Config->new( config_file => $self->config_file,
                                     force_array => 0 );

    $self->_set_config( $config );

    return $self;
}

### public methods ###

sub run {

    my ( $self ) = @_;

    $self->logger->debug( "Running." );

    # change our process name
    $0 = "netsage raw json importer";

    # create JSON object
    my $json = JSON::XS->new();

    $self->_set_json( $json );

    # connect to rabbit queues
    $self->_rabbit_connect();

    # continually consume messages from rabbit queue, making sure we have to acknowledge them
    $self->logger->debug( 'Starting RabbitMQ consume loop.' );

    return $self->_consume_loop();

    #if ( !$success ) {
    #    $self->logger->debug('Error retrieving data');
    #    return;
    #}
    #$self->logger->debug('Data retrieved; sending to rabbit');
    #return $self->_publish_data();

}

sub start {

    my ( $self ) = @_;

    $self->logger->debug( "Starting." );

    # flag that we're running
    $self->_set_is_running( 1 );

    # change our process name
    $0 = "netsage_flow_anonymizer [worker]";

    # setup signal handlers
    $SIG{'TERM'} = sub {

        $self->logger->info( "Received SIG TERM." );
        $self->stop();
    };

    $SIG{'HUP'} = sub {

        $self->logger->info( "Received SIG HUP." );
    };


    # create JSON object
    my $json = JSON::XS->new();

    $self->_set_json( $json );

    # connect to rabbit queues
    $self->_rabbit_connect();

    # continually consume messages from rabbit queue, making sure we have to acknowledge them
    $self->logger->debug( 'Starting RabbitMQ consume loop.' );

    return $self->_consume_loop();
}

sub stop {

    my ( $self ) = @_;

    $self->logger->debug( 'Stopping.' );

    # this will cause the consume loop to exit
    $self->_set_is_running( 0 );
}

### private methods ###

sub _consume_loop {

    my ( $self ) = @_;

    while ( 1 ) {

        # have we been told to stop?
        if ( !$self->is_running ) {

            $self->logger->debug( 'Exiting consume loop.' );
            return 0;
        }

        # receive the next rabbit message
        my $rabbit_message;

        try {

            $rabbit_message = $self->rabbit->recv( QUEUE_FETCH_TIMEOUT );
        }

        catch {

            $self->logger->error( "Error receiving rabbit message: $_" );

            # reconnect to rabbit since we had a failure
            $self->_rabbit_connect();
        };

        # didn't get a message?
        if ( !$rabbit_message ) {

            $self->logger->debug( 'No message received.' );

            # re-enter loop to retrieve the next message
            next;
        }

        # try to JSON decode the messages
        my $messages;

        try {

            $messages = $self->json->decode( $rabbit_message->{'body'} );
        }

        catch {

            $self->logger->error( "Unable to JSON decode message: $_" );
        };

        if ( !$messages ) {

            try {

                # reject the message and do NOT requeue it since its malformed JSON
                $self->rabbit->reject( RAW_FLOWS_QUEUE_CHANNEL, $rabbit_message->{'delivery_tag'}, 0 );
            }

            catch {

                $self->logger->error( "Unable to reject rabbit message: $_" );

                # reconnect to rabbit since we had a failure
                $self->_rabbit_connect();
            };
        }

        # retrieve the next message from rabbit if we couldn't decode this one
        next if ( !$messages );

        # make sure its an array (ref) of messages
        if ( ref( $messages ) ne 'ARRAY' ) {

            $self->logger->error( "Message body must be an array." );

            try {

                # reject the message and do NOT requeue since its not properly formed
                $self->rabbit->reject( RAW_FLOWS_QUEUE_CHANNEL, $rabbit_message->{'delivery_tag'}, 0 );
            }

            catch {

                $self->logger->error( "Unable to reject rabbit message: $_" );

                # reconnect to rabbit since we had a failure
                $self->_rabbit_connect();
            };

            next;
        }

        my $num_messages = @$messages;
        $self->logger->debug( "Processing message containing $num_messages anonymizations to perform." );

        my $t1 = time();

        my $success = $self->_consume_messages( $messages );

        my $t2 = time();
        my $delta = $t2 - $t1;

        $self->logger->debug( "Processed $num_messages updates in $delta seconds." );

        # didn't successfully consume the messages, so reject but requeue the entire message to try again
        if ( !$success ) {

            $self->logger->debug( "Rejecting rabbit message, requeueing." );

            try {

                $self->rabbit->reject( 1, $rabbit_message->{'delivery_tag'}, 1 );
            }

            catch {

                $self->logger->error( "Unable to reject rabbit message: $_" );

                # reconnect to rabbit since we had a failure
                $self->_rabbit_connect();
            };
        }

        # successfully consumed message, acknowledge it to rabbit
        else {

            $self->logger->debug( "Acknowledging successful message." );

            try {

                $self->rabbit->ack( 1, $rabbit_message->{'delivery_tag'} );
            }

            catch {

                $self->logger->error( "Unable to acknowledge rabbit message: $_" );

                # reconnect to rabbit since we had a failure
                $self->_rabbit_connect();
            };
        }
    }
}

sub _consume_messages {

    my ( $self, $messages ) = @_;

    # gather all messages to process
    my $flows_to_process = [];

    # handle every message that came within the rabbit message
    foreach my $message ( @$messages ) {

        # make sure message is an object/hash (ref)
        if ( ref( $message ) ne 'HASH' ) {

            $self->logger->error( "Messages must be an object/hash of data, skipping." );
            next;
        }
        my $src_ip = $message->{'src_ip'};
        my $dest_ip = $message->{'dest_ip'};
        my $src_port = $message->{'src_port'};
        my $dest_port = $message->{'dest_port'};
        my $src_asn = $message->{'src_asn'};
        my $dest_asn = $message->{'dest_asn'};
        my $start_time = $message->{'start_time'};
        my $end_time = $message->{'end_time'};


	my $message = {
        src_ip => $src_ip,
        dest_ip => $dest_ip,
        src_port => $src_port,
        dest_port => $dest_port,
        src_asn => $src_asn,
        dest_asn => $dest_asn,
        start_time => $start_time,
        end_time => $end_time,
    };

    # TODO: Add some sanity checks on the message

	# include this to our list of messages to process if it was valid
	push( @$flows_to_process, $message ) if $message;
    }

    # anonymize all of the data across all messages
    my $success = 1;

    try {

        $self->_anonymize_messages( $flows_to_process ) if ( @$flows_to_process > 0 );
    }

    catch {

        $self->logger->error( "Error anonymizing messages: $_" );
        $success = 0;
    };

    return $success;
}

sub _anonymize_messages {
    # TODO: the actual anonymization in a better way
    my ( $self, $messages ) = @_;

    my $finished_messages = $messages;

    foreach my $message ( @$messages ) {
        $message->{'src_ip'} = '';
        $message->{'dest_ip'} = '';

    }
    my $num = @$finished_messages;

    # send a max of 100 messages at a time to rabbit
    my $it = natatime( 100, @$finished_messages );

    my $queue = $self->config->get( '/config/rabbit/anonymized-queue' );

    while ( my @finished_messages = $it->() ) {

	$self->rabbit->publish( ANONYMIZED_FLOWS_QUEUE_CHANNEL, $queue, $self->json->encode( \@finished_messages ), {'exchange' => ''} );
    }
}

sub _publish_data {
    my ( $self ) = @_;
    if ( !$self->json_data ) {
        $self->logger->info("No data found to publish");
        return;
    }
    my $data = $self->json_data;
    
    # send a max of 100 messages at a time to rabbit
    my $it = natatime( 100, @$data );

    my $queue = $self->config->get( '/config/rabbit/anonymized-queue' );

    while ( my @finished_messages = $it->() ) {

        $self->rabbit->publish( ANONYMIZED_FLOWS_QUEUE_CHANNEL, $queue, $self->json->encode( \@finished_messages ), {'exchange' => ''} );

    }

}


sub _rabbit_connect {

    my ( $self ) = @_;

    my $rabbit_host = $self->config->get( '/config/rabbit/host' );
    my $rabbit_port = $self->config->get( '/config/rabbit/port' );
    my $input_queue = $self->config->get( '/config/rabbit/raw-queue' );
    my $output_queue = $self->config->get( '/config/rabbit/anonymized-queue' );

    while ( 1 ) {

        $self->logger->info( "Connecting to RabbitMQ $rabbit_host:$rabbit_port." );

        my $connected = 0;

        try {

            my $rabbit = Net::AMQP::RabbitMQ->new();

            $rabbit->connect( $rabbit_host, {'port' => $rabbit_port} );

	    # open channel to the pending queue we'll read from
            $rabbit->channel_open( RAW_FLOWS_QUEUE_CHANNEL );
            $rabbit->queue_declare( RAW_FLOWS_QUEUE_CHANNEL, $input_queue, {'auto_delete' => 0} );
            $rabbit->basic_qos( RAW_FLOWS_QUEUE_CHANNEL, { prefetch_count => QUEUE_PREFETCH_COUNT } );
            $rabbit->consume( RAW_FLOWS_QUEUE_CHANNEL, $input_queue, {'no_ack' => 0} );

	    # open channel to the finished queue we'll send to
            $rabbit->channel_open( ANONYMIZED_FLOWS_QUEUE_CHANNEL );
            $rabbit->queue_declare( ANONYMIZED_FLOWS_QUEUE_CHANNEL, $output_queue, {'auto_delete' => 0} );


            $self->_set_rabbit( $rabbit );

            $connected = 1;
        }

        catch {

            $self->logger->error( "Error connecting to RabbitMQ: $_" );
        };

        last if $connected;

        $self->logger->info( "Reconnecting after " . RECONNECT_TIMEOUT . " seconds..." );
        sleep( RECONNECT_TIMEOUT );
    }
}

1;
