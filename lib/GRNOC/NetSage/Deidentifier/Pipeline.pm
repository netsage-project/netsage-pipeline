package GRNOC::NetSage::Deidentifier::Pipeline;

use strict;
use warnings;

use Moo;

use GRNOC::Log;
use GRNOC::Config;

use Net::AMQP::RabbitMQ;
use JSON::XS;
use Math::Round qw( nlowmult nhimult );
use List::MoreUtils qw( natatime );
use Try::Tiny;
use Data::Validate::IP;
use Net::IP;

use Data::Dumper;

### constants ###

use constant QUEUE_PREFETCH_COUNT => 20;
use constant QUEUE_PREFETCH_COUNT_NOACK => 0;
use constant QUEUE_FETCH_TIMEOUT => 10 * 1000;
use constant RECONNECT_TIMEOUT => 10;

### required attributes ###

has config_file => ( is => 'ro',
                required => 1 );

has logging_file => ( is => 'ro',
                      required => 1 );

has process_name => ( is => 'ro',
                      required => 1 );

# input queue, identified by name
#has input_queue_name => ( is => 'ro',
#                     required => 1 );

# output queue, identified by name
#has output_queue_name => ( is => 'ro',
#                     required => 1 );

has handler => ( is => 'rwp');
#                 required => 1 );

### internal attributes ###

has logger => ( is => 'rwp' );

has config => ( is => 'rwp' );

has is_running => ( is => 'rwp',
                    default => 0 );

has rabbit_config => ( is => 'rwp' );

has task_type => ( is => 'rwp' );

# ack_messages indicates whether to ack rabbit messages. normally, this should be 1 (enabled).
# if you disable this, we don't ack the rabbit messages and they go back in the queue. 
# usually this is only desired for testing purposes. Don't touch this unless you
# know what you're doing.
has ack_messages => ( is => 'rwp',
                      default => 1 );

has rabbit_input => ( is => 'rwp' );

has rabbit_output => ( is => 'rwp' );

has input_queue => ( is => 'rwp' );

has input_channel => ( is => 'rwp' );

has output_queue => ( is => 'rwp' );

has output_channel => ( is => 'rwp' );

has batch_size => ( is => 'rwp' );

has json => ( is => 'rwp' );


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

    $self->_rabbit_config();

    return $self;
}

### public methods ###

sub start {

    my ( $self, $task_type ) = @_;
    $self->_set_task_type( $task_type );

    $self->logger->debug( "Starting." );

    # flag that we're running
    $self->_set_is_running( 1 );

    # change our process name
    $0 = $self->process_name . " [worker]";

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

    if ( $self->task_type && $self->task_type eq "noinput" ) {
        $self->start_noinput();

    } else {
        # continually consume messages from rabbit queue, making sure we have to acknowledge them
        $self->logger->debug( 'Starting RabbitMQ consume loop.' );

    }
    return $self->_consume_loop();
}

sub start_noinput {
# _process_messages takes an argument of an arrayref of data to process
# and then it calls the specified handler function on it
#sub _process_messages {
    my ( $self, $flows_to_process ) = @_;

    return $self->_consume_noinput();
}


sub stop {

    my ( $self ) = @_;

    $self->logger->debug( 'Stopping.' );

    # this will cause the consume loop to exit
    $self->_set_is_running( 0 );
}

### private methods ###

sub _consume_noinput {

    my ( $self ) = @_;

    while( 1 ) {
        # have we been told to stop?
        if ( !$self->is_running ) {

            $self->logger->debug( 'Exiting consume loop.' );
            return 0;
        }
        my $handler = $self->handler;
        $self->handler->( $self );
        sleep 5;

    }

}

sub _consume_loop {

    my ( $self ) = @_;


    my $input_queue = $self->rabbit_config->{'input'}->{'queue'};
    my $input_channel = $self->rabbit_config->{'input'}->{'channel'};
    my $rabbit = $self->rabbit_input;

    while ( 1 ) {

        # have we been told to stop?
        if ( !$self->is_running ) {

            $self->logger->debug( 'Exiting consume loop.' );
            return 0;
        }

        # receive the next rabbit message
        my $rabbit_message;

        try {

            $rabbit_message = $rabbit->recv( QUEUE_FETCH_TIMEOUT );
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
                $rabbit->reject( $input_channel, $rabbit_message->{'delivery_tag'}, 0 );
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
                $rabbit->reject( $input_queue, $rabbit_message->{'delivery_tag'}, 0 );
            }

            catch {

                $self->logger->error( "Unable to reject rabbit message: $_" );

                # reconnect to rabbit since we had a failure
                $self->_rabbit_connect();
            };

            next;
        }

        my $num_messages = @$messages;
        $self->logger->debug( "Processing message containing $num_messages to process." );

        my $t1 = time();

        my $success = $self->_consume_messages( $messages );

        my $t2 = time();
        my $delta = $t2 - $t1;

        $self->logger->debug( "Processed $num_messages updates in $delta seconds." );

        # didn't successfully consume the messages, so reject but requeue the entire message to try again
        if ( !$success ) {

            $self->logger->debug( "Rejecting rabbit message, requeueing." );

            try {

                $rabbit->reject( $input_channel, $rabbit_message->{'delivery_tag'}, 1 );
            }

            catch {

                $self->logger->error( "Unable to reject rabbit message: $_" );

                # reconnect to rabbit since we had a failure
                $self->_rabbit_connect();
            };
        }

        # successfully consumed message, acknowledge it to rabbit
        else {
            if ( $self->ack_messages ) {

                $self->logger->debug( "Acknowledging successful message." );

                try {

                    $rabbit->ack( $input_channel, $rabbit_message->{'delivery_tag'} );
                }

                catch {

                    $self->logger->error( "Unable to acknowledge rabbit message: $_" );

                    # reconnect to rabbit since we had a failure
                    $self->_rabbit_connect();
                };
            } else {
                # do nothing
                $self->logger->warn("Not acking message");
            }
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

        # include this to our list of messages to process if it was valid
        push( @$flows_to_process, $message ) if $message;

    }

    # process all of the data across all messages
    my $success = 1;


    try {

        $flows_to_process = $self->_process_messages( $flows_to_process ) if ( @$flows_to_process > 0 );
    }

    catch {

        $self->logger->error( "Error processing messages: $_" );
        $success = 0;
    };
    # if we're caching in memory, we don't need to push to rabbit - just return success
    if ( $self->task_type && $self->task_type eq "caching" ) {
        return $success;
    }

    try {

        $self->_publish_data( $flows_to_process ) if ( @$flows_to_process > 0 );
    }

    catch {

        $self->logger->error( "Error publishing messages: $_" );
        $success = 0;
    };

    return $success;
}

sub _publish_data {
    my ( $self, $messages ) = @_;
    my $batch_size = $self->rabbit_config->{'output'}->{'batch_size'};
    if ( ! @$messages ) {
        $self->logger->info("No data found to publish");
        return;
    }

    # send a max of $batch_size messages at a time to rabbit
    my $it = natatime( $batch_size, @$messages );
    $self->logger->debug("Publishing up to " . $batch_size . " messages per batch ( " . @$messages . " ) ");

    my $queue = $self->rabbit_config->{'output'}->{'queue'};
    my $channel = $self->rabbit_config->{'output'}->{'channel'};

    $self->_rabbit_connect();
    while ( my @finished_messages = $it->() ) {

       $self->rabbit_output->publish( $channel, $queue, $self->json->encode( \@finished_messages ), {'exchange' => ''} );
    }
    return $messages;

}



# _process_messages takes an argument of an arrayref of data to process
# and then it calls the specified handler function on it
sub _process_messages {
    my ( $self, $flows_to_process ) = @_;

    my $handler = $self->handler;
    $flows_to_process = $self->handler->( $self, $flows_to_process );

    return $flows_to_process;

}

sub _rabbit_config {
    my $self = shift;

    my $rabbit_config = {};
    my @directions = ('input', 'output');

    foreach my $direction ( @directions ) {
        $rabbit_config->{$direction} = {};

        my $rabbit_host = $self->config->get( "/config/rabbit_$direction/host" );
        $rabbit_config->{$direction}->{'host'} = $rabbit_host;

        my $rabbit_port = $self->config->get( "/config/rabbit_$direction/port" );
        $rabbit_config->{$direction}->{'port'} = $rabbit_port;

        my $rabbit_username = $self->config->get( "/config/rabbit_$direction/username" );
        $rabbit_config->{$direction}->{'username'} = $rabbit_username;

        my $rabbit_password = $self->config->get( "/config/rabbit_$direction/password" );
        $rabbit_config->{$direction}->{'password'} = $rabbit_password;

        my $rabbit_vhost = $self->config->get( "/config/rabbit_$direction/vhost" );
        $rabbit_config->{$direction}->{'vhost'} = $rabbit_vhost if defined $rabbit_vhost;

        my $rabbit_ssl = $self->config->get( "/config/rabbit_$direction/ssl" ) || 0;
        $rabbit_config->{$direction}->{'ssl'} = $rabbit_ssl if defined $rabbit_ssl;

        my $rabbit_ca_cert = $self->config->get( "/config/rabbit_$direction/cacert" );
        $rabbit_config->{$direction}->{'ca_cert'} = $rabbit_ca_cert if defined $rabbit_ca_cert;

        my $batch_size = $self->config->get("/config/rabbit_$direction/batch_size") || 100;
        $rabbit_config->{$direction}->{'batch_size'} = $batch_size if defined $batch_size;

        my $queue = $self->config->get("/config/rabbit_$direction/queue");
        $rabbit_config->{$direction}->{'queue'} = $queue;

        my $channel = $self->config->get("/config/rabbit_$direction/channel");
        $rabbit_config->{$direction}->{'channel'} = $channel;

    }
    $self->_set_rabbit_config($rabbit_config);

}

sub _rabbit_connect {

    my ( $self ) = @_;

    my $rabbit_config = $self->rabbit_config;

    my %connected = ();
    $connected{'input'} = 0;
    $connected{'output'} = 0;
    while ( 1 ) {

    my @directions = ('input', 'output');

    foreach my $direction ( @directions ) {

        my $rabbit_host = $rabbit_config->{ $direction }->{'host'};
        my $rabbit_port = $rabbit_config->{ $direction }->{'port'};
        my $rabbit_username = $rabbit_config->{ $direction }->{'username'};
        my $rabbit_password = $rabbit_config->{ $direction }->{'password'};
        my $rabbit_ssl = $rabbit_config->{ $direction }->{'ssl'};
        my $rabbit_ca_cert = $rabbit_config->{ $direction }->{'ca_cert'};
        my $rabbit_vhost = $rabbit_config->{ $direction }->{'vhost'};
        my $rabbit_channel = $rabbit_config->{ $direction }->{'channel'};
        my $rabbit_queue = $rabbit_config->{ $direction }->{'queue'};

        $self->logger->info( "Connecting to $direction RabbitMQ $rabbit_host:$rabbit_port." );

        $connected{ $direction } = 0;

        try {


            my $rabbit = Net::AMQP::RabbitMQ->new();
            my $params = {};
            $params->{'port'} = $rabbit_port;
            $params->{'user'} = $rabbit_username if $rabbit_username;
            $params->{'password'} = $rabbit_password if $rabbit_password;
            if ( $rabbit_ssl ) {
                $params->{'ssl'} = $rabbit_ssl;
                $params->{'ssl_verify_host'} = 0;
                $params->{'ssl_cacert'} = $rabbit_ca_cert;
            }
            if ( $rabbit_vhost ) {
                $params->{'vhost'} = $rabbit_vhost;
            }

            $rabbit->connect( $rabbit_host, $params );

            if ( $direction eq 'input' ) {
                # open channel to the pending queue we'll read from
                $rabbit->channel_open( $rabbit_channel );
                $rabbit->queue_declare( $rabbit_channel, $rabbit_queue, {'auto_delete' => 0} );
                if ( $self->ack_messages ) {
                    $rabbit->basic_qos( $rabbit_channel, { prefetch_count => QUEUE_PREFETCH_COUNT } );
                } else {
                    #$rabbit->basic_qos( $rabbit_channel );
                    $rabbit->basic_qos( $rabbit_channel, { prefetch_count => QUEUE_PREFETCH_COUNT_NOACK } );
                }
                $rabbit->consume( $rabbit_channel, $rabbit_queue, {'no_ack' => 0} );

                } else {
        #open channel to the finished queue we'll send to
        #
            $rabbit->channel_open( $rabbit_channel );
            $rabbit->queue_declare( $rabbit_channel, $rabbit_queue, {'auto_delete' => 0} );
#
#

            }

            my $setter = "_set_rabbit_$direction";
            $self->$setter( $rabbit );

#
#            $self->_set_rabbit( $rabbit );
#
            $connected{ $direction } = 1;
        }

        catch {

            $self->logger->error( "Error connecting to $direction RabbitMQ: $_" );
        };

        if ( $connected{'input'} && $connected{'output'}) {
            return;
        };
        next if $connected{ $direction };

        $self->logger->info( "Reconnecting $direction after " . RECONNECT_TIMEOUT . " seconds..." );
        sleep( RECONNECT_TIMEOUT );
    } # end foreach directoin
}# end while 1 
}

1;
