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
    my $msg_count = $self->msg_count;;

    foreach my $row (@$messages ) {
        my $src = $row->{'meta'}->{'src_ip'};
        my $dst = $row->{'meta'}->{'dst_ip'};
        my $src_meta = $scireg->get_metadata( $src );
#warn "src_meta\n" . Dumper $src_meta;

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
    warn "finished batch ... time elapsed: " . $delta;
    warn "messages " . $msg_count . " per second: " . ( $msg_count  / $delta );
    return $messages;
}

# recursively walk hash and format characters as needed
sub hash_walk {
    my ($self, $hash, $key_list )  = @_;
    #warn "now walking hash" . Dumper $hash;
    foreach my $k ( keys %$hash ) { 
        my $v = $hash->{ $k };
         # Keep track of the hierarchy of keys, in case
         # our callback needs it.
         push @$key_list, $k;
        #warn "k: $k; v: " . Dumper $v;
        #warn "v:\n" . Dumper $v;
        #warn "REF " . ref($v);

        if (ref($v) eq 'HASH' ) {
            # Recurse. I think this never happens with current data structure?
            #warn "CURRENT V " . Dumper $v;
            #warn "RECURSING INTO: " . $v;
            $self->hash_walk($v, $key_list);
        } elsif ( ref($v) eq 'ARRAY' ) {
            #warn "V is an ARRAY " . Dumper $v;
            my $i = 0;
            foreach my $row (@$v) {
                #warn "ARRAY ROW: " . Dumper $row;
                #warn "ROW REF " . ref ($row );
                if ( ref ( $row ) eq 'HASH' ) {
                    #warn "RECURSING INTO ARRAY ROW " . Dumper $row;
                    $self->hash_walk($row, $key_list);
                } elsif ( ref ($row) eq '' ) {
                    #warn "no ref row " . Dumper $row;
                    $row = _convert_chars($row);
                    $v->[$i] = $row;

                }
                $i++;
            }
        } else {
            #warn "converting characters - ref: '" . ref($v) . "' , " . $v;
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
