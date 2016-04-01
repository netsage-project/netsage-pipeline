package GRNOC::NetSage::Anonymizer::FlowMover;

use strict;
use warnings;


use Moo;

extends 'GRNOC::NetSage::Anonymizer::Pipeline';

use GRNOC::Log;
use GRNOC::Config;

use Data::Validate::IP;
use Net::IP;
use Digest::SHA;

use Data::Dumper;


### internal attributes ###
            
has handler => ( is => 'rwp');

### constructor builder ###

sub BUILD {

    my ( $self ) = @_;

    my $config = $self->config;
    warn "config: " . Dumper $config->get('/config');
    $self->_set_handler( sub { $self->_process_messages(@_) } );

    return $self;
}

### private methods ###

# expects an array of data for it to process
# in this case we want to copy the messages unmodified, so returns the original data
sub _process_messages {
    # TODO: the actual anonymization in a better way
    my ( $self, $messages ) = @_;

    #my $finished_messages = $messages;
    #warn "messages " . Dumper $messages;

    return $messages;
}

1;
