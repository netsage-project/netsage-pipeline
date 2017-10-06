package GRNOC::NetSage::Deidentifier::FlowCache;

use strict;
use warnings;

use Moo;

extends 'GRNOC::NetSage::Deidentifier::Pipeline';

use GRNOC::Log;
use GRNOC::Config;

use Clone qw(clone);
use IPC::ShareLite qw( :lock );
use Storable qw(freeze thaw);
use Try::Tiny;
use Number::Bytes::Human qw(format_bytes);
use Time::Duration;
use Time::HiRes;

use Data::Dumper;

### internal attributes ###

has handler => ( is => 'rwp');

#has input_data => ( is => 'rwp', default => [] );

has flow_cache => ( is => 'rwp', ); # default => sub { {} } );

has ipc_key => ( is => 'rwp', default => 'flow' );

has share => ( is => 'rwp' );

has acceptable_offset => ( is => 'rwp', default => 5 );

has finished_flows => ( is => 'rwp', default => sub { [] } );

has sensors => ( is => 'rwp', default => sub { {} } );

#has ipv4_bits_to_strip => ( is => 'rwp', default => 8 );
#has ipv6_bits_to_strip => ( is => 'rwp', default => 64 );

### constructor builder ###

sub BUILD {

    my ( $self ) = @_;

    my $config = $self->config; # $self->config;
    #my $config = $config_obj->get('/config');
    #warn "config: " . Dumper $config;

    my $ipc_key = $config->{'worker'}->{'ipc-key'};
    $self->_set_ipc_key( $ipc_key ) if defined $ipc_key;

    $self->_get_sensors();

    $self->_init_cache();

    $self->_set_handler( sub { $self->_run_flow_caching(@_) } );

    return $self;
}

### private methods ###
sub _init_cache {
    my $self = shift;

    my $cache;
    my $ipc_key = $self->ipc_key;

    my $share = IPC::ShareLite->new(
        -key => $ipc_key,
        -create => 'yes',
        -destroy => 'no',
    ) or die $!;

    if ( not defined $self->flow_cache ) {
        #warn "initially creating cache ..."; 
        $cache = {};
        $share->store(freeze ( $cache ) );
    } else {
        #warn "thawing cache ...";
        $cache = thaw( $share->fetch );
    }
    $self->_set_flow_cache( $cache );

    $self->_set_share( $share );


}

sub _get_sensors {
    my ( $self ) = @_;

    my $collections = $self->config->{'collection'};

    my %sensors = ();

    if ( ref($collections) ne "ARRAY" ) {
        $collections = [ $collections ];
    }
    warn "collections " . Dumper $collections;

    foreach my $collection ( @$collections ) {
        #warn "collection " . Dumper $collection;
        my $sensor = $collection->{'sensor'};
        $sensors{ $sensor } = 1;
    }
    warn "sensors " . Dumper \%sensors;

    $self->_set_sensors( \%sensors );

}

sub _run_flow_caching {
    my ( $self, $caller, $input_data ) = @_;

    #$self->_init_cache() if ( not defined( $self->flow_cache ) ) or ( keys %{ $self->flow_cache } == 0 );

    #warn "flow cache start of run: " . keys %{ $self->flow_cache };

    my $share = $self->share;
    my $cache = $self->flow_cache;
    my @keys = keys %$cache;
    warn "keys " . Dumper \@keys;
    my $key1 = pop @keys;
    warn "key1 " . Dumper $key1;
    #warn "cache: " . Dumper $cache; #->{ $key1 };
    my $sensors = $self->sensors;
    #warn "sensors " . Dumper $sensors;
    warn "thawing cache ...";
    $share->lock( LOCK_SH );

    $cache = thaw( $share->fetch );

    $share->unlock( );


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

    foreach my $row (@$input_data) {
        # if any one of our five tuple is undefined, log a message and skip this message
        if ( not defined $row->{'meta'}->{'protocol'} ) {
            $self->logger->debug( 'no protocol! ' . Dumper $row );
        }
        next if not defined $row->{'meta'}->{'src_ip'};
        next if not defined $row->{'meta'}->{'dst_ip'};
        next if not defined $row->{'meta'}->{'dst_port'};
        next if not defined $row->{'meta'}->{'protocol'};

        my $five_tuple = $row->{'meta'}->{'src_ip'};
        $five_tuple .= $row->{'meta'}->{'src_port'};
        $five_tuple .= $row->{'meta'}->{'dst_ip'};
        $five_tuple .= $row->{'meta'}->{'dst_port'};
        $five_tuple .= $row->{'meta'}->{'protocol'};

        my $sensor_id = $row->{'meta'}->{'sensor_id'};

        #warn "five_tuple: $five_tuple\n";

        my $start = $row->{'start'};
        my $end = $row->{'end'};
        my $duration = $end - $start;
        if ( $cache->{$sensor_id}  ) {
            #warn "SENSOR ALREADY FOUND";
        } else {
            $cache->{$sensor_id} = {};
        }

        #warn Dumper $row;
        if ( $cache->{ $sensor_id }->{$five_tuple}  ) {
            #warn "FIVE TUPLE ALREADY FOUND";
        } else {
            $cache->{ $sensor_id }->{$five_tuple} = {};
        }
        #$cache->{$five_tuple}->{'start'} = $start;
        #$cache->{$five_tuple}->{'end'} = $end;
        #warn "start: $start; end: $end";
        my $last_start = $cache->{ $sensor_id }->{$five_tuple}->{'last_start'} || 0;
        my $last_end = $cache->{ $sensor_id }->{$five_tuple}->{'last_end'} || 0;
        if ( $start <= $last_start ) { # TODO: should this be < $last_end?
            #print "overlap: start: " . localtime( $start ) . " last_start: " . localtime( $last_start ) . "\n";
            #print "overlap: end:   " . localtime( $end ) . " last_end: " . localtime( $last_end ) . "\n";
            $overlaps++;
            #print "flows overlap ($overlaps) -- what should we do about overlapping flows?\n";
            #print localtime( $start ) . "\t-\t" . localtime( $end ) . "\tcurrent\n";
            #print localtime( $last_start ) . "\t-\t" . localtime( $last_end ) . "\tlast\n";
        }
        $last_start = $start;
        $last_end = $end;

        $cache->{ $sensor_id }->{$five_tuple}->{'last_start'} = $last_start;
        $cache->{ $sensor_id }->{$five_tuple}->{'last_end'} = $last_end;

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

        #my $flows_temp = [];
        if ( defined ( $cache->{ $sensor_id }->{$five_tuple}->{'flows'} ) ) {
            #warn "flow already defined";
            #$flows_temp = $cache->{$five_tuple}->{'flows'};
        } else { 
            $cache->{ $sensor_id }->{$five_tuple}->{'flows'} = [];
            #$flows_temp = [];
        }
        push @{ $cache->{ $sensor_id }->{$five_tuple}->{'flows'} }, $row;

        if ( !defined $max_flows || @{ $cache->{ $sensor_id }->{$five_tuple}->{'flows'} } > $max_flows ) {
            $max_flows = @{ $cache->{ $sensor_id }->{$five_tuple}->{'flows'} };
        }

    }

    #warn "caache after caching " . Dumper $cache;
    #$cache->{'test'} = 1;
    #warn "min start: $min_start";
    #warn "max start: $max_start";
    #warn "min end: $min_end";
    #warn "max end: $max_end";
    #warn "min duration: " . duration($min_duration);
    #warn "max duration: " . duration($max_duration);
    #warn "min bytes: " . format_bytes($min_bytes, bs => 1000);
    #warn "max bytes: " . format_bytes($max_bytes, bs => 1000);
    #warn "max flows: $max_flows";

    #%cache = %{ clone (\%cache) };


    $share->lock( LOCK_EX );

    $share->store(freeze ( $cache ) );

    $share->unlock( );

    $self->_set_flow_cache( $cache );



    #warn "cache in cache at end: " . keys ( %$cache ); # . Dumper %cache;


    # Flow stitching is a special case in the pipeline in that it doesn't simply
    # return values to be stitched and then exit. It explicitly publishes them itself
    # and returns an empty array when it's done. This is because it's a long-running process
    # that looks at flows over time
    #$self->_publish_flows( );

    #return $finished_messages;
    # Return just a dummy array so it knows we were successful
    return [ 'finished' ];
}

1;
