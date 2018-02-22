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
use Text::Unidecode;
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

    foreach my $row (@$messages ) {
        my $src = $row->{'meta'}->{'src_ip'};
        my $dst = $row->{'meta'}->{'dst_ip'};
        my $src_meta = $scireg->get_metadata( $src );
        $self->hash_walk( $src_meta );

        my $dst_meta = $scireg->get_metadata( $dst );
        $self->hash_walk( $dst_meta );

        if ( $src_meta ) {
            delete $src_meta->{'addresses_str'};
            delete $src_meta->{'addresses'};
            delete $src_meta->{'ip_block_id'};
            $row->{'meta'}->{'scireg'}->{'src'} = $src_meta;
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

# recursively walk hash and format characters as needed
sub hash_walk {
    my ($self, $hash) = @_;
    while (my ($k, $v) = each %$hash) {

        if (ref($v) eq 'HASH' ) {
            # Recurse.
            $self->hash_walk($v);
        } elsif ( ref($v) eq 'ARRAY' ) {
            foreach my $row (@$v) {
                if ( ref ( $row ) eq 'HASH' ) {
                    $self->hash_walk($row);
                }
            }
        } else {
            # Otherwise, convert the characters
            my $newv = _convert_chars( $v );
            $hash->{ $k } = $newv;
        }

    }
}

# formatting callback
sub _convert_chars {
    my ( $input ) = @_;
    $input = unidecode( $input );
    return $input;
}
1;
