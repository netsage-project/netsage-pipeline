package GRNOC::NetSage::Anonymizer::FlowTagger;


use Moo;

use GRNOC::NetSage::Anonymizer::Pipeline;
use GRNOC::Log;
use GRNOC::Config;

use Data::Validate::IP;
use Net::IP;

use Data::Dumper;


### required attributes ###

has config_file => ( is => 'ro',
                required => 1 );

has logging_file => ( is => 'ro',
                      required => 1 );

### internal attributes ###
            
has logger => ( is => 'rwp' );

has config => ( is => 'rwp' );

has pipeline => ( is => 'rwp' );

has handler => ( is => 'rwp');


### constructor builder ###

sub BUILD {

    my ( $self ) = @_;

    # create and store logger object
    my $grnoc_log = GRNOC::Log->new( config => $self->logging_file );
    my $logger = GRNOC::Log->get_logger();

    $self->_set_logger( $logger );

    # create the Pipeline object, which handles the Rabbit queues

    my $pipeline = GRNOC::NetSage::Anonymizer::Pipeline->new(
        config_file => $self->config_file,
        logging_file => $self->logging_file,
        input_queue_name => 'raw',
        output_queue_name => 'tagged',
        handler => sub { $self->_tag_messages(@_) },
        process_name => 'netsage_flowtagger',
    );
    $self->_set_pipeline( $pipeline );

    return $self;
}

### public methods ###

sub start {

    my ( $self ) = @_;
    return $self->pipeline->start();

}

### private methods ###

# expects an array of data for it to anonymize
# returns the anonymized array
sub _tag_messages {
    # TODO: the actual tagging
    my ( $self, $caller, $messages ) = @_;

    my $finished_messages = $messages;

    foreach my $message ( @$messages ) {
        # do some tagging
        # geotagging
        # asn 
        # etc
        #
        # $message->{'src_ip'} = $self->_anonymize_ip( $message->{'src_ip'} );
        # $message->{'dest_ip'} = $self->_anonymize_ip( $message->{'dest_ip'} );
    }

    return $finished_messages;
}

1;
