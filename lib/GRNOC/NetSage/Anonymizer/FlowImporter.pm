package GRNOC::NetSage::Anonymizer::FlowImporter;

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

### required attributes ###

has config_file => ( is => 'ro',
                required => 1 );

has logging_file => ( is => 'ro',
                      required => 1 );

has jsonfile => ( is => 'ro',
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

    my $success = $self->_get_json_data();

    if ( !$success ) {
        $self->logger->debug('Error retrieving data');
        return;
    }
    $self->logger->debug('Data retrieved; sending to rabbit');
    return $self->_publish_data();

}

sub _get_json_data {
    my ( $self ) = @_;
    my $file = $self->jsonfile;
    my $json_data;
    {
        local $/; #Enable 'slurp' mode
        open my $fh, "<", $file || die ('error loading json file');
        $json_data = <$fh>;
        close $fh;
    }

    my $data;
    try {
        $data = $self->json->decode( $json_data );
    }
    catch {
        $self->logger->warn( "Unable to JSON decode message: $_" );
    };

    $self->_set_json_data( $data );

    if (!$data) {
        return;
    } else {
        return 1;
    }

};

### private methods ###

sub _publish_data {
    my ( $self ) = @_;
    if ( !$self->json_data ) {
        $self->logger->info("No data found to publish");
        return;
    }
    my $data = $self->json_data;
    
    # send a max of 100 messages at a time to rabbit
    my $it = natatime( 100, @$data );

    my $queue = $self->config->get( '/config/rabbit/raw-queue' );

    while ( my @finished_messages = $it->() ) {

        $self->rabbit->publish( RAW_FLOWS_QUEUE_CHANNEL, $queue, $self->json->encode( \@finished_messages ), {'exchange' => ''} );

    }

}


sub _rabbit_connect {

    my ( $self ) = @_;

    my $rabbit_host = $self->config->get( '/config/rabbit/host' );
    my $rabbit_port = $self->config->get( '/config/rabbit/port' );
    my $raw_data_queue = $self->config->get( '/config/rabbit/raw-queue' );

    while ( 1 ) {

        $self->logger->info( "Connecting to RabbitMQ $rabbit_host:$rabbit_port." );

        my $connected = 0;

        try {

            my $rabbit = Net::AMQP::RabbitMQ->new();

            $rabbit->connect( $rabbit_host, {'port' => $rabbit_port} );

	    # open channel to the pending queue we'll read from
            $rabbit->channel_open( RAW_FLOWS_QUEUE_CHANNEL );
            $rabbit->queue_declare( RAW_FLOWS_QUEUE_CHANNEL, $raw_data_queue, {'auto_delete' => 0} );
            $rabbit->basic_qos( RAW_FLOWS_QUEUE_CHANNEL, { prefetch_count => QUEUE_PREFETCH_COUNT } );

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
