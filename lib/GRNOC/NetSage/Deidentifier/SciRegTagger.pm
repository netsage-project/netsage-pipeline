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
use Time::HiRes qw( time );


use Data::Dumper;


### internal attributes ###

has handler => ( is => 'rwp');

has json => ( is => 'rwp' );

has scireg => ( is => 'rwp' );

has start_time => ( is => 'rwp' );
has msg_count => ( is => 'rwp' );

### constructor builder ###

sub BUILD {

    my ( $self ) = @_;

    $self->_set_start_time( time() );
    $self->_set_msg_count( 0 );

    my $config = $self->config;
    $self->_set_handler( sub { $self->_process_messages(@_) } );
    my $json = JSON::XS->new();
    $self->_set_json( $json );

    my $scireg = new GRNOC::NetSage::Deidentifier::DataService::ScienceRegistry(
            config => $config,
            logger => $self->logger
    );
    $self->_set_scireg( $scireg );

    $self->logger->debug( "Config:\n" . Dumper ($config ) );

    return $self;
}

### private methods ###

# expects an array of data for it to process
# in this case we want to copy the messages unmodified, so returns the original data
sub _process_messages {
    my ( $self, $messages ) = @_;
    my $scireg = $self->scireg;
    my $msg_count = $self->msg_count;;

    foreach my $row (@$messages ) {
        my $src = $row->{'meta'}->{'src_ip'};
        my $dst = $row->{'meta'}->{'dst_ip'};
        my $src_meta = $scireg->get_metadata( $src );

        my $dst_meta = $scireg->get_metadata( $dst );

        if ( $src_meta ) {
            delete $src_meta->{'addresses_str'};
            delete $src_meta->{'addresses'};
            delete $src_meta->{'ip_block_id'};
            $self->hash_walk( $src_meta, [] );
            $row->{'meta'}->{'scireg'}->{'src'} = $src_meta;
        }
        if ( $dst_meta ) {
            my $dst = $row->{'meta'}->{'dst_ip'};
            delete $dst_meta->{'addresses_str'};
            delete $dst_meta->{'addresses'};
            delete $dst_meta->{'ip_block_id'};
            $self->hash_walk( $dst_meta, [] );
            $row->{'meta'}->{'scireg'}->{'dst'} = $dst_meta;
        }
        $msg_count++;
        $self->_set_msg_count( $msg_count );

    }

    my $start = $self->start_time;
    my $now = time();
    my $delta = $now - $start;
    return $messages;
}

# recursively walk hash and format characters as needed
sub hash_walk {
    my ($self, $hash, $key_list )  = @_;
    foreach my $k ( keys %$hash ) { 
        my $v = $hash->{ $k };
         # Keep track of the hierarchy of keys, in case
         # our callback needs it.
         push @$key_list, $k;

        if (ref($v) eq 'HASH' ) {
            # Recurse. I think this never happens with current data structure?
            $self->hash_walk($v, $key_list);
        } elsif ( ref($v) eq 'ARRAY' ) {
            my $i = 0;
            foreach my $row (@$v) {
                if ( ref ( $row ) eq 'HASH' ) {
                    $self->hash_walk($row, $key_list);
                } elsif ( ref ($row) eq '' ) {
                    $row = _convert_chars($row);
                    $v->[$i] = $row;

                }
                $i++;
            }
        } else {
            # Otherwise, convert the characters
            my $newv = _convert_chars( $v );
            $hash->{ $k } = $newv;
        }
        pop @$key_list;
    }
}

# formatting callback
sub _convert_chars {
    my ( $input ) = @_;
    if ( !defined ( $input ) ) {
        return undef;
    }
    $input = unidecode( $input );
    return $input;
}
1;
