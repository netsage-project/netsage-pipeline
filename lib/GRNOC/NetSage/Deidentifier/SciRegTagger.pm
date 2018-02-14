package GRNOC::NetSage::Deidentifier::SciRegTagger;

use strict;
use warnings;

use Moo;

extends 'GRNOC::NetSage::Deidentifier::Pipeline';

use GRNOC::Log;
use GRNOC::Config;

use Data::Validate::IP;
use Net::IP;
use Text::Unidecode; # TODO: REMOVE THIS once TSDS bug is fixed
use Digest::SHA;
use utf8;
use JSON::XS;



use Data::Dumper;


### internal attributes ###

has handler => ( is => 'rwp');

has json => ( is => 'rwp' );

### constructor builder ###

sub BUILD {

    my ( $self ) = @_;

    my $config = $self->config;
    warn "config " . Dumper $config;
    $self->_set_handler( sub { $self->_process_messages(@_) } );
    my $json = JSON::XS->new();
    $self->_set_json( $json );

    return $self;
}

### private methods ###

# expects an array of data for it to process
# in this case we want to copy the messages unmodified, so returns the original data
sub _process_messages {
    my ( $self, $messages ) = @_;

    warn "MESSAGES\n" . Dumper $messages;

    return $messages;

}

1;
