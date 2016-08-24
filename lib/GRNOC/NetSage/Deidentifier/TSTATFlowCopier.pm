package GRNOC::NetSage::Deidentifier::TSTATFlowCopier;

use strict;
use warnings;

use Moo;
use Socket;
use Socket6;
use Geo::IP;
use Data::Validate::IP;
use Net::IP;

use GRNOC::NetSage::Deidentifier::Pipeline;
use GRNOC::Log;
use GRNOC::Config;

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

    # create and store config object
    my $config = GRNOC::Config->new( config_file => $self->config_file,
                                     force_array => 0 );

    $self->_set_config( $config );


    # create the Pipeline object, which handles the Rabbit queues

    my $pipeline = GRNOC::NetSage::Deidentifier::Pipeline->new(
        config_file => $self->config_file,
        logging_file => $self->logging_file,
        input_queue_name => 'raw',
        output_queue_name => 'tstat_clone',
        handler => sub { $self->_tag_messages(@_) },
        process_name => 'netsage_tstat_flow_copier',
        #ack_messages => 0, # set to 0 to prevent acking messages (they get requeued)
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

# For this operation, we don't need to do anything to the data. 
sub _tag_messages {
    my ( $self, $caller, $messages ) = @_;

    my $finished_messages = $messages;

    return $finished_messages;
}

1;
