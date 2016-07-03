package GRNOC::NetSage::Deidentifier::FlowCache;

use strict;
use warnings;

use Moo;

extends 'GRNOC::NetSage::Deidentifier::Pipeline';

use GRNOC::Log;
use GRNOC::Config;

use Clone qw(clone);
#use JSON::XS;
use IPC::Shareable;
use Try::Tiny;
use Number::Bytes::Human qw(format_bytes);
use Time::Duration;
use Time::HiRes;

use Data::Dumper;

### internal attributes ###

has handler => ( is => 'rwp');

#has input_data => ( is => 'rwp', default => [] );

has flow_cache => ( is => 'rwp', ); # default => sub { {} } );

has knot => ( is => 'rwp' );

has acceptable_offset => ( is => 'rwp', default => 5 );

has finished_flows => ( is => 'rwp', default => sub { [] } );

#has ipv4_bits_to_strip => ( is => 'rwp', default => 8 );
#has ipv6_bits_to_strip => ( is => 'rwp', default => 64 );

### constructor builder ###

sub BUILD {

    my ( $self ) = @_;

    my $config_obj = $self->config;
    my $config = $config_obj->get('/config');
    # warn "config: " . Dumper $config;
    #my $anon = $config->{'deidentification'};
    #my $ipv4_bits = $config->{'deidentification'}->{'ipv4_bits_to_strip'};
    #my $ipv6_bits = $config->{'deidentification'}->{'ipv6_bits_to_strip'};
    #$self->_set_ipv4_bits_to_strip( $ipv4_bits );
    #$self->_set_ipv6_bits_to_strip( $ipv6_bits );
    $self->_set_handler( sub { $self->_run_flow_caching(@_) } );


    return $self;
}

### private methods ###
sub _init_cache {
    my $self = shift;
    my $glue = 'flow';
    my %options = (
        create    => 1,
        exclusive => 0,
        mode      => 0644,
        destroy   => 0,
    );
    my %cache; # = %{ $self->flow_cache };
    #IPC::Shareable->clean_up;

    my $knot = tie %cache, 'IPC::Shareable', $glue, { %options } or die "cache: tie failed\n";
    #IPC::Shareable->clean_up_all;
    #warn "cache: " . Dumper %cache;

    $cache{'set_from_cacher'} = 'y3Ah!!!!';

    $self->_set_flow_cache( \%cache );
    $self->_set_knot( $knot );

}

my $knot;
sub _run_flow_caching {
    my ( $self, $caller, $input_data ) = @_;

    #$self->_init_cache() if ( not defined( $self->flow_cache ) ) or ( keys %{ $self->flow_cache } == 0 );
    my $glue = 'flow';
    my %options = (
        create    => 1,
        exclusive => 0,
        mode      => 0644,
        destroy   => 0,
    );
    my %cache;
    my %ipc_cache;

    #if ( ( not defined( $self->flow_cache ) ) or ( keys %{ $self->flow_cache } == 0 ) ) {}
    if ( ( not defined( $self->flow_cache ) ) or ( not defined $knot ) ) {
        #IPC::Shareable->clean_up;
        #
        warn "tying knot ...";

        $knot = tie %cache, 'IPC::Shareable', $glue, { %options } or die "cache: tie failed\n";
        #IPC::Shareable->clean_up_all;
        #warn "cache: " . Dumper %cache;

        #$cache{'set_from_cacher'} = 'y3Ah!!!!';
        $self->_set_flow_cache( \%cache );
        $self->_set_knot( $knot );

    }

    #%cache = %ipc_cache;

    warn "flow cache start of run: " . keys %{ $self->flow_cache };

    #my %cache = %{ $self->flow_cache };
    #my $knot = $self->knot;

    my $min_start;
    my $max_start;
    my $min_end;
    my $max_end;
    my $min_bytes;
    my $max_bytes;
    my $max_flows;
    my $min_duration;
    my $max_duration;
    my $overlaps = 0;


    #$knot->shlock;
    foreach my $row (@$input_data) {
        my $five_tuple = $row->{'meta'}->{'src_ip'};
        $five_tuple .= $row->{'meta'}->{'src_port'};
        $five_tuple .= $row->{'meta'}->{'dst_ip'};
        $five_tuple .= $row->{'meta'}->{'dst_port'};
        $five_tuple .= $row->{'meta'}->{'protocol'};
        #warn "five_tuple: $five_tuple\n";

        my $start = $row->{'start'};
        my $end = $row->{'end'};
        my $duration = $end - $start;

        #warn Dumper $row;
        if ( $cache{$five_tuple}  ) {
            #warn "FIVE TUPLE ALREADY FOUND";
        } else {
            #$cache{$five_tuple} = {};
        }
        #$cache{$five_tuple}->{'start'} = $start;
        #$cache{$five_tuple}->{'end'} = $end;
        #warn "start: $start; end: $end";
        my $last_start = $cache{$five_tuple}->{'last_start'} || 0;
        my $last_end = $cache{$five_tuple}->{'last_end'} || 0;
        if ( $start <= $last_start ) { # TODO: should this be < $last_end?
            #print "overlap: start: " . localtime( $start ) . " last_start: " . localtime( $last_start ) . "\n";
            print "flows overlap -- what should we do about overlapping flows?\n";
            $overlaps++;
            #print localtime( $start ) . "\t-\t" . localtime( $end ) . "\tcurrent\n";
            #print localtime( $last_start ) . "\t-\t" . localtime( $last_end ) . "\tlast\n";
        }
        $last_start = $start;
        $last_end = $end;

        $cache{$five_tuple}->{'last_start'} = $last_start;
        $cache{$five_tuple}->{'last_end'} = $last_end;

        if ( !defined $min_end || $end < $min_end ) {
            $min_end = $end;
        }
        if ( !defined $max_end || $end > $max_end ) {
            $max_end = $end;
        }

        if ( !defined $min_start || $start < $min_start ) {
            $min_start = $start;
        }
        if ( !defined $max_start || $start > $max_start ) {
            $max_start = $start;
        }
        if ( !defined $min_duration || $duration < $min_duration ) {
            $min_duration = $duration;
        }
        if ( !defined $max_duration || $duration > $max_duration ) {
            $max_duration = $duration;
        }

        my $bytes = $row->{'values'}->{'num_bits'} / 8;
        if ( !defined $min_bytes || $bytes < $min_bytes ) {
            $min_bytes = $bytes;
        }

        if ( !defined $max_bytes || $bytes > $max_bytes ) {
            $max_bytes = $bytes;
        }

        if ( defined ( $cache{$five_tuple}->{'flows'} ) ) {
            #warn "flow already defined";
        } else { 
            $cache{$five_tuple}->{'flows'} = [];
        }
        push @{ $cache{$five_tuple}->{'flows'} }, $row;

        if ( !defined $max_flows || @{ $cache{$five_tuple}->{'flows'} } > $max_flows ) {
            $max_flows = @{ $cache{$five_tuple}->{'flows'} };
        }

    }
    #$cache{'test'} = 1;
    #$knot->remove();
    #$knot->shunlock;
    warn "min start: $min_start";
    warn "max start: $max_start";
    warn "min end: $min_end";
    warn "max end: $max_end";
    warn "min duration: " . duration($min_duration);
    warn "max duration: " . duration($max_duration);
    warn "min bytes: " . format_bytes($min_bytes, bs => 1000);
    warn "max bytes: " . format_bytes($max_bytes, bs => 1000);
    warn "max flows: $max_flows";

    %cache = %{ clone (\%cache) };

    $self->_set_flow_cache( \%cache );

    warn "cache in cache at end: " . keys ( %cache ); # . Dumper %cache;


    # Flow stitching is a special case in the pipeline in that it doesn't simply
    # return values to be stitched and then exit. It explicitly publishes them itself
    # and returns an empty array when it's done. This is because it's a long-running process
    # that looks at flows over time
    #$self->_publish_flows( );

    #return $finished_messages;
    return [];
}

1;
