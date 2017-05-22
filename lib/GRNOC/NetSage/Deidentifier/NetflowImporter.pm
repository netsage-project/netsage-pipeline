package GRNOC::NetSage::Deidentifier::NetflowImporter;

use strict;
use warnings;

use Moo;

extends 'GRNOC::NetSage::Deidentifier::Pipeline';

use GRNOC::Log;
use GRNOC::Config;

use POSIX qw( floor  );
use Net::AMQP::RabbitMQ;
use JSON::XS;
use Math::Round qw( nlowmult nhimult );
use List::MoreUtils qw( natatime );
use Try::Tiny;
use Date::Parse;
use Date::Format;
use File::stat;
use File::Find::Rule;
use File::Find::Rule::Age;
use Path::Class;
use Storable qw( store retrieve );
use Sys::Hostname;

use Data::Dumper;

### required attributes ###

has config_file => ( is => 'ro',
                required => 1 );

has logging_file => ( is => 'ro',
                      required => 1 );

### optional attributes ###

has sensor_id => ( is => 'rwp', default => hostname() );

### internal attributes ###

has flow_path => ( is => 'rwp' );

has json => ( is => 'rwp' );

has json_data => ( is => 'rwp' );

has status => ( is => 'rwp' );

has min_bytes => ( is => 'rwp',
                   default => 500000000 ); # 500 MB

has flow_batch_size => ( is => 'rwp' );

has status_cache => ( is => 'rwp',
                       default => sub { {} } );

has cache_file => ( is => 'rwp' );

# min_file_age must be one of "older" or "newer". $age must match /^(\d+)([DWMYhms])$/ where D, W, M, Y, h, m and s are "day(s)", "week(s)", "month(s)", "year(s)", "hour(s)", "minute(s)" and "second(s)"
# see http://search.cpan.org/~pfig/File-Find-Rule-Age-0.2/lib/File/Find/Rule/Age.pm
has min_file_age => ( is => 'rwp',
                      default => '1h' );

has nfdump_path => ( is => 'rwp' );
#                     default => '/usr/bin/nfdump' )

has flow_type => ( is => 'rwp', 
                     default => 'netflow' );

### constructor builder ###

sub BUILD {

    my ( $self ) = @_;

    my $config_obj = $self->config;
    my $config = $config_obj->get('/config');
    my $sensor_id = $config_obj->get( '/config/sensor' );
    if ( defined ( $sensor_id )) {
        $self->_set_sensor_id( $sensor_id );
    }

    my $flow_batch_size =  $config->{'worker'}->{'flow-batch-size'};
    my $cache_file = $config->{'worker'}->{'cache-file'} if not defined $self->cache_file;
    $cache_file = '/var/cache/netsage/netflow_importer.cache' if not defined $cache_file;
    $self->_set_cache_file( $cache_file );
    $self->logger->debug("cache file: " . $cache_file);

    my $flow_path = $self->flow_path;

    $flow_path = $config->{'worker'}->{'flow-path'} if not defined $flow_path;
    $self->_set_flow_path( $flow_path );
    $self->logger->debug("flow path: $flow_path");

    my $min_file_age = $self->min_file_age;
    $min_file_age = $config->{'worker'}->{'min-file-age'} if defined $config->{'worker'}->{'min-file-age'};
    $self->_set_min_file_age( $min_file_age );

    my $flow_type = $self->flow_type;
    $flow_type = $config->{'worker'}->{'flow-type'} if defined $config->{'worker'}->{'flow-type'};
    $self->_set_flow_type( $flow_type );
    $self->logger->debug("flow type: $flow_type");

    $self->_set_flow_batch_size( $flow_batch_size );
    $self->_set_handler( sub{ $self->_run_netflow_import(@_) } );

    $self->_set_nfdump_path( $config->{'worker'}->{'nfdump-path'} )
        if defined $config->{'worker'}->{'nfdump-path'};

    my $min_bytes = $self->min_bytes;
    $min_bytes = $config->{'worker'}->{'min-bytes'} if defined  $config->{'worker'}->{'min-bytes'};
    $self->_set_min_bytes( $min_bytes );

    # create JSON object
    my $json = JSON::XS->new();

    $self->_set_json( $json );

    $self->_read_cache();

    return $self;
}

### public methods ###

sub _run_netflow_import {

    my ( $self ) = @_;

    # get flow data
    my $success = $self->_get_flow_data();

    # publish flow data
    return $self->_publish_flows();

}

sub _get_flow_data {
    my ( $self ) = @_;

    my $flow_batch_size = $self->flow_batch_size;
    my $status = $self->status_cache;

    my $path = $self->flow_path;
    my $min_bytes = $self->min_bytes;
    $self->logger->debug("path: $path");
    $self->logger->debug("min_file_age: " . $self->min_file_age );
    my @files = File::Find::Rule
            ->file()
            ->age( 'older', $self->min_file_age )
            ->name( 'nfcapd.*' )
            ->relative(1)
	        ->extras({ follow => 1 })
            ->in($path);

    my @filepaths = ();
    for(my $i=0; $i<@files; $i++) {
        my $file = $files[$i];
#$self->logger->debug("file: $file");
        my $file_path = dir( $path, $file ) . "";
        my $stats = stat($file_path);
        my $abs = file( $file_path );
        my $rel = $abs->relative( $path ) . "";
        if ( exists ( $status->{ $rel } ) ) {
            my $entry = $status->{ $rel };
            if ( (!defined $stats) or (!defined $entry) ) {
                next;
            }
            my $mtime_cache = $entry->{'mtime'};
            my $size_cache  = $entry->{'size'};

            # If file size and last-modified time are unchanged, skip it
            if ( $mtime_cache == $stats->mtime
                && $size_cache == $stats->size ) {
                next;
            }
        }
        push @filepaths, dir( $path, $file ) . "";

    }
    @filepaths = sort @filepaths;
    my $success = $self->_get_nfdump_data(\@filepaths);



}

sub _get_nfdump_data {
    my ( $self, $flowfiles ) = @_;

    my $status = $self->status_cache;

    my $flow_batch_size = $self->flow_batch_size;

    my $path = $self->flow_path;
    my $min_bytes = $self->min_bytes;

    my $config_path = $self->nfdump_path;
    my $nfdump = '/usr/bin/nfdump';
    # if configured nfdump path is a file and is executable, use it
    if ( defined $config_path ) {
        if ( -f $config_path && -x _ ) {
            $nfdump = $config_path
        } else {
            $self->logger->error("Invalid nfdump path specified; quitting");
            $self->_set_is_running( 0 );
            return;

        }

    }

    my @all_data = ();
    foreach my $flowfile ( @$flowfiles ) {

        # quit if the process has been told to stop
        if ( !$self->is_running ) {
            $self->logger->debug("Quitting flowfile loop and returning from _get_nfdump_data()");
            return;
        }

        my $stats = stat($flowfile);

        my $command = "$nfdump -r '$flowfile'";
	    $command .= " -a"; # perform aggregation based on 5 tuples
        $command .= ' -o csv -o "fmt:%ts,%te,%td,%sa,%da,%sp,%dp,%pr,%flg,%fwd,%stos,%ipkt,%ibyt,%opkt,%obyt,%in,%out,%sas,%das,%smk,%dmk,%dtos,%dir,%nh,%nhb,%svln,%dvln,%ismc,%odmc,%idmc,%osmc,%mpls1,%mpls2,%mpls3,%mpls4,%mpls5,%mpls6,%mpls7,%mpls8,%mpls9,%mpls10,%ra,%eng,%bps,%pps,%bpp"';
        $command .= ' -L +' . $min_bytes;
        $command .= " -N -q";
        $command .= ' |';
        $self->logger->debug(" command:\n$command\n");

        my $fh;
        open($fh, $command);

        my $i = 0;
        while ( my $line = <$fh> ) {
            my ( $ts,$te,$td,$sa,$da,$sp,$dp,$pr,$flg,$fwd,$stos,$ipkt,$ibyt,$opkt,$obyt,$in,$out,$sas,$das,$smk,$dmk,$dtos,$dir,$nh,$nhb,$svln,$dvln,$ismc,$odmc,$idmc,$osmc,$mpls1,$mpls2,$mpls3,$mpls4,$mpls5,$mpls6,$mpls7,$mpls8,$mpls9,$mpls10,$ra,$eng,$bps,$pps,$bpp ) = split( /\s*,\s*/, $line);

            my $start = str2time( $ts );
            my $end   = str2time( $te );

            if ( !defined $start || !defined $end ) {
                #$self->logger->error("Invalid line in $flowfile. $!. Start or End time is undefined.");
                next;
            }

            my $sum_bytes = $ibyt + $obyt;
            my $sum_packets = $ipkt + $opkt;

            my $row = {};
            $row->{'type'} = 'flow';
            $row->{'interval'} = 600;
            $row->{'meta'} = {};
            $row->{'meta'}->{'flow_type'} = $self->flow_type || 'netflow';
            $row->{'meta'}->{'src_ip'} = $sa;
            $row->{'meta'}->{'src_port'} = $sp;
            $row->{'meta'}->{'dst_ip'} = $da;
            $row->{'meta'}->{'dst_port'} = $dp;
            $row->{'meta'}->{'protocol'} = getprotobynumber( $pr );
            $row->{'meta'}->{'sensor_id'} = $self->sensor_id;
            $row->{'meta'}->{'src_asn'} = $sas;
            $row->{'meta'}->{'dst_asn'} = $das;
            $row->{'start'} = $start;
            $row->{'end'} = $end;

            $row->{'values'} = {};
            $row->{'values'}->{'duration'} = $td;
            $row->{'values'}->{'num_bits'} = $sum_bytes * 8;
            $row->{'values'}->{'num_packets'} = $sum_packets;
            $row->{'values'}->{'bits_per_second'} = $bps;
            $row->{'values'}->{'packets_per_second'} = $pps;


            push @all_data, $row;
            if ( @all_data % $flow_batch_size == 0 ) {
                $self->logger->debug("processed " . @all_data . " (up to $flow_batch_size) flows; publishing ... ");
                $self->_set_json_data( \@all_data );
                $self->_publish_flows();
                @all_data = ();
            }
        }
        # publish any remaining data
        # TODO: improve performance here by waiting until we have full batches
        $self->_set_json_data( \@all_data );
        $self->_publish_flows();
        @all_data = ();

        my $abs = file( $flowfile );
        my $rel = $abs->relative( $path ) . "";
        $status->{$rel} = {
            mtime => $stats->mtime,
            size => $stats->size
        };
        $self->_set_status_cache( $status );
        $self->_write_cache();
    }

    if ( $self->run_once ) {
        $self->logger->debug("only running once, stopping");
            $self->_set_is_running( 0 );
    }

    if (!@all_data) {
        return;
    } else {
        return 1;
    }


};

### private methods ###

sub _write_cache {
    my ( $self ) = @_;
    my $filename = $self->cache_file;
    my $status = $self->status_cache;
    store $status, $filename;

}


sub _read_cache {
    my ( $self ) = @_;
    my $filename = $self->cache_file;
    my $status = $self->status_cache;
    if ( not -f $filename ) {
        open my $fh, '>', $filename
            or die "Cache file $filename does not exist, and failed to created it: $!\n";
        close $fh;
        store $status, $filename;
    }
    $status = retrieve $filename;
    $self->_set_status_cache( $status );

}
sub _publish_flows {
    my $self = shift;
    my $flows = $self->json_data;
    if ( defined $flows ) {
        $self->_publish_data( $flows );
    }

    $self->_set_json_data( [] );
}

1;
