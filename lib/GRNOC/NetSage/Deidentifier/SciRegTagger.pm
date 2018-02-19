package GRNOC::NetSage::Deidentifier::SciRegTagger;

use strict;
use warnings;

use Moo;

extends 'GRNOC::NetSage::Deidentifier::Pipeline';

use GRNOC::Log;
use GRNOC::Config;
use GRNOC::NetSage::Deidentifier::DataService::ScienceRegistry;

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

has scireg => ( is => 'rwp' );

### constructor builder ###

sub BUILD {

    my ( $self ) = @_;

    my $config = $self->config;
    warn "config " . Dumper $config;
    $self->_set_handler( sub { $self->_process_messages(@_) } );
    my $json = JSON::XS->new();
    $self->_set_json( $json );

    my $scireg = new GRNOC::NetSage::Deidentifier::DataService::ScienceRegistry(
            config => $config,
            logger => $self->logger
    );
    $self->_set_scireg( $scireg );

    return $self;
}

### private methods ###

# expects an array of data for it to process
# in this case we want to copy the messages unmodified, so returns the original data
sub _process_messages {
    my ( $self, $messages ) = @_;
    my $scireg = $self->scireg;

    #warn "MESSAGES\n" . Dumper $messages;
    foreach my $row (@$messages ) {
        #warn "row:\n" . Dumper $row;
        my $src = $row->{'meta'}->{'src_ip'};
        my $dst = $row->{'meta'}->{'dst_ip'};
        warn "querying src: $src";
        my $src_meta = $scireg->get_metadata( $src );
        my $dst_meta = $scireg->get_metadata( $dst );
        if ( $src_meta ) {
            delete $src_meta->{'addresses_str'};
            delete $src_meta->{'addresses'};
            delete $src_meta->{'ip_block_id'};
            $row->{'meta'}->{'scireg'}->{'src'} = $src_meta;
            #warn "src_meta\n" . Dumper $src_meta;
        }
        if ( $dst_meta ) {
            my $dst = $row->{'meta'}->{'dst_ip'};
            delete $dst_meta->{'addresses_str'};
            delete $dst_meta->{'addresses'};
            delete $dst_meta->{'ip_block_id'};
            $row->{'meta'}->{'scireg'}->{'dst'} = $dst_meta;
        }

    }

    return $messages;
}
1;
