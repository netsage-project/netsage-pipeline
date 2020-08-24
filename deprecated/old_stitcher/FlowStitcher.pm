package GRNOC::NetSage::Deidentifier::FlowStitcher;

use strict;
use warnings;

use Moo;

extends 'GRNOC::NetSage::Deidentifier::Pipeline';

use GRNOC::Log;
use GRNOC::Config;

#use Data::Validate::IP;
#use Net::IP;
#use Digest::SHA;

#use JSON::XS;
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

has flow_cache => ( is => 'rwp' );

has ipc_key => ( is => 'rwp', default => 'flow' );

has stats => ( is => 'rw', default => sub { {} } );

has acceptable_offset => ( is => 'rwp', default => 5 );

has finished_flows => ( is => 'rwp', default => sub { [] } );

has latest_timestamp => ( is => 'rwp', default => 0 );

### constructor builder ###

sub BUILD {

    my ( $self ) = @_;

    my $config = $self->config;

    my $ipc_key = $config->{'worker'}->{'ipc-key'};
    $self->_set_ipc_key( $ipc_key ) if defined $ipc_key;
    #warn "BUILD ipc_key: $ipc_key";

    $self->_set_handler( sub { $self->_run_flow_stitching(@_) } );

    #$self->_run_flow_stitching();

    return $self;
}

### private methods ###
sub _init_cache {
    my $self = shift;
    my %options = (
        create    => 0,
        exclusive => 0,
        mode      => 0644,
        destroy   => 0,
    );
    my %cache;

    $self->_set_flow_cache( \%cache );

    $self->stats( {
            stitched_flow_count => 0,
        });

}

# expects an array of data for it to stitch
# returns a stitched array? TODO: update this
sub _run_flow_stitching {
    my ( $self, $caller, $messages ) = @_;

    $self->_stitch_flows( );


    # Flow stitching is a special case in the pipeline in that it doesn't simply
    # return values to be stitched and then exit. It explicitly publishes them itself
    # and returns an empty array when it's done. This is because it's a long-running process
    # that looks at flows over time
    $self->_publish_flows( );

}

sub _publish_flows {
    my $self = shift;
    my $flows = $self->finished_flows;

    $self->_publish_data( $flows );
    $self->_set_finished_flows( [] );
}

sub _set_values_strings {
    my $obj = shift;
    foreach my $key ( keys %$obj ) {
        my $val = $obj->{$key};
        next if not defined $val;
        if ( ref($val) eq 'HASH' ) {
            $val = _set_values_strings( $val );
        } else {
            $obj->{$key} = "$val";
        }
    }

    return $obj;
}

sub _stitch_flows {
    my ( $self ) = @_;

    my $ipc_key = $self->ipc_key;
    #warn "_stitch_flow, ipc_key: $ipc_key";

    my $cache_all;
    my $share = IPC::ShareLite->new(
        -key => $ipc_key,
        -create => 0,
        -destroy => 0,
    ) or die $!;

    $share->lock( LOCK_SH );
    if ( not defined $share ) {
        $cache_all = {};
    } else {
        #warn "thawing cache ...";
        my $fetch = $share->fetch;
    if ( $share->fetch ) {
            $cache_all = thaw( $share->fetch );
    } else {
        $cache_all = {};
    }
    }
    $self->_set_flow_cache( $cache_all );
    $share->unlock();

    my $finished_flows = $self->finished_flows;

    my $overlaps = 0;
    my $stitchable_flows = 0;
    my $stitched_flow_count = 0;

    my $latest_timestamp = $self->latest_timestamp;

    while( my ( $sensor, $cache ) = each %$cache_all ) {


    while( my ( $five_tuple, $flow_container ) = each %$cache ) {
        my $flows = $flow_container->{'flows'};
        if ( @$flows > 0 ) {
            my $previous_flow;
            my $i = 0;
            my %flows_to_remove = ();
            foreach my $flow (@$flows ) {
                $flow->{'stitching_finished'} = 0;
                $flow->{'no_previous'} = 0 if not $flow->{'no_previous'};
                my $start = $flow->{'start'};
                my $end = $flow->{'end'};
                $flow->{'flow_num'} = $i;
                $latest_timestamp = $end if $end > $latest_timestamp;
                # If there is a previous flow
                if ( $previous_flow ) {
                    # If this flow and the previous flow go together, merge them
                    # and remove previous flow
                    if ( $self->_can_stitch_flow( $previous_flow->{'end'}, $start ) ) {
                        $flow = $self->_stitch_flow( $previous_flow, $flow );
                        $flows_to_remove{$i-1} = 1;
                        $stitched_flow_count++;
                        $stitchable_flows++;
                    } else {
                        # If can't stitch flows, that means that flow has ended and can be output and removed from the cache
                        $flow->{'stitching_finished'} = 1;
                        push @$finished_flows, \%{ clone ( $flow )};
                        $flows_to_remove{$i} = 1;
                    }

                } else {
                    $flow->{'no_previous'}++;
                    if ( $flow->{'no_previous'} <= 1 ) {
                        #warn "no previous flow #1; caching";
                    } else {
                        #warn "no previous flow #2; finished";
                        $flow->{'stitching_finished'} = 1;
                        push @$finished_flows, \%{ clone ( $flow )};
                        $flows_to_remove{$i} = 1;
                    }

                }
                $previous_flow = $flow;
                $i++;
            }

            for (my $i=@$flows-1; $i>=0; $i--) {
                if ( ( $self->acceptable_offset + $flows->[$i]->{'end'} < $latest_timestamp ) && ( not $flows_to_remove{$i} ) ) {
                    $flows_to_remove{$i} = 1;
                    push @$finished_flows, \%{ clone ( $flows->[$i] )};
                }
                if ( $flows_to_remove{$i} ) {
                    splice @$flows, $i, 1;
                }

            }

            if ( @$flows < 1 ) {
                # no flows for this five tuple; remove it
                delete $cache->{$five_tuple};

            }

        } else {
            # no flows for this five tuple; remove it
            delete $cache->{$five_tuple};

        }

    }

    if ( keys %{ $cache_all->{ $sensor } } < 1 ) {
        delete $cache_all->{ $sensor };

    }

    $self->_set_latest_timestamp( $latest_timestamp );

    $self->_set_finished_flows( $finished_flows );

    my $stats = $self->stats;
    $stats->{'stitched_flow_count'} += $stitched_flow_count;

    # find stats on the final, stitched flows for this run
    my $max_stitched_duration = 0;
    my $max_stitched_bytes = 0;
    my $min_stitched_duration;
    while( my ( $five_tuple, $flow_container ) = each %$cache ) {
        foreach my $row ( @{$flow_container->{'flows'}} ) {
            my $bytes = $row->{'values'}->{'num_bits'} / 8;
            my $duration = $row->{'values'}->{'duration'};
            if ( $duration > $max_stitched_duration ) {
                $max_stitched_duration = $duration;
            }
            if ( $bytes > $max_stitched_bytes ) {
                $max_stitched_bytes = $bytes;
            }
        }

    }

    $self->stats( $stats );


    } # end while sensors


    # save updated cache

    $self->_set_flow_cache( $cache_all );
    $share->lock( LOCK_EX );
    $share->store( freeze( $cache_all ) );
    $share->unlock();

}

# stitches an individual flow
sub _stitch_flow {
    my ($self, $flowA, $flowB) = @_;

    my $flow1;
    my $flow2;

    # make sure flow1 comes before flow2;
    if ( $flowA->{'start'} < $flowB->{'start'} ) {
        $flow1 = $flowA;
        $flow2 = $flowB;
    } else {
        $flow1 = $flowB;
        $flow2 = $flowA;
    }

    $flow1->{'end'} = $flow2->{'end'};
    $flow1->{'values'}->{'duration'} += $flow2->{'values'}->{'duration'};
    $flow1->{'values'}->{'num_bits'} += $flow2->{'values'}->{'num_bits'};
    $flow1->{'values'}->{'num_packets'} += $flow2->{'values'}->{'num_packets'};
    $flow1->{'stitched'} = 1;

    return $flow1;

}

sub _can_stitch_flow {
    my ($self, $time1, $time2) = @_;
    if ( abs ( $time1 - $time2 ) < $self->acceptable_offset ) {
        return 1;
    } else {
        return 0;
    }
}

1;
