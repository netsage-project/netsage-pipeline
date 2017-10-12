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
use DateTime;
use File::stat;
use File::Find;
use Path::Class;
use Path::Tiny;
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

has instance_id => ( is => 'rwp', default => 0 );

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
                      default => '0' );

has cull_enable => ( is => 'rwp',
                    default => 0 );

# wait until files are this old to delete them after processing
# in days
has cull_ttl => ( is => 'rwp',
                    default => 3 );

# cull after reading $cull_count files
has cull_count => ( is => 'rwp',
                    default => 10 );

has nfdump_path => ( is => 'rwp' );

has flow_type => ( is => 'rwp',
                   default => 'netflow' );

my @files;

### constructor builder ###

sub BUILD {

    my ( $self ) = @_;

    #my $config_obj = $self->config;
    my $config = $self->config;
    my $sensor_id = $config->{ 'sensor' } || hostname();
    if ( defined ( $sensor_id ) ) {
        $self->_set_sensor_id( $sensor_id );
    }
    my $instance_id = $config->{ 'instance' };

    # for some reason if you leave <instance></instance> blank, you get
    # an empty hashref back. work around that.
    if ( defined ( $instance_id ) && ! ( ref $instance_id eq ref {} ) ) {
        $self->_set_instance_id( $instance_id );
    }

    $self->logger->debug("instance id: " . $self->instance_id);

    my $flow_batch_size =  $config->{'worker'}->{'flow-batch-size'};
    my $cache_file = $config->{'worker'}->{'cache-file'} if not defined $self->cache_file;
    $cache_file = '/var/cache/netsage/netflow_importer.cache' if not defined $cache_file;
    $self->_set_cache_file( $cache_file );
    $self->logger->debug("cache file: " . $cache_file);

    my $flow_path = $self->flow_path;

    $flow_path = $config->{'worker'}->{'flow-path'} if not defined $flow_path;
    $self->_set_flow_path( $flow_path );
    $self->logger->debug("flow path: " . Dumper $flow_path);

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

    my $cull_enable = $self->cull_enable;
    $cull_enable = $config->{'worker'}->{'cull-enable'} if defined  $config->{'worker'}->{'cull-enable'};
    $self->_set_cull_enable( $cull_enable );

    my $cull_ttl = $self->cull_ttl;
    $cull_ttl = $config->{'worker'}->{'cull-ttl'} if defined  $config->{'worker'}->{'cull-ttl'};
    $self->_set_cull_ttl( $cull_ttl );

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

sub _get_params {
    my ( $self, $collection ) = @_;
    my %params = ();
    my $config = $self->config;

    my $path = $collection->{'flow-path'} || $self->flow_path;
    my $sensor = $collection->{'sensor'} || $self->sensor_id;
    my $instance = $collection->{'instance'} || $self->instance_id || '';
    my $flow_type = $collection->{'flow-type'} || $self->flow_type || 'netflow';


    %params = (
        path => $path,
        sensor => $sensor,
        instance => $instance,
        flow_type => $flow_type
    );


    return \%params;
}

sub _get_flow_data {
    my ( $self ) = @_;

    my $flow_batch_size = $self->flow_batch_size;
    my $status = $self->status_cache;

    my $collections = $self->config->{'collection'};


    if ( ref($collections) ne "ARRAY" ) {
        $collections = [ $collections ];
    }

    foreach my $collection ( @$collections ) {

        my $path = $collection->{'flow-path'} || $self->flow_path;
        my $sensor = $collection->{'sensor'} || hostname();

        my %params = %{ $self->_get_params( $collection ) };

        $params{'flow-path'} = $path;
        $params{'sensor'} = $sensor;

        #my $path = $self->flow_path;
        my $min_bytes = $self->min_bytes;
        $self->logger->debug("path: $path");
        $self->logger->debug("min_file_age: " . $self->min_file_age );

        $self->_cull_flow_files( $path );

        try {
            # TODO: don't forget to ignore nfcapd.current.*
            my @paths = ( $path );
            #my $ref = $self->can('find_nfcapd');
            @files = ();
            find({ wanted => sub { find_nfcapd($self, \%params)  }, follow => 1 }, @paths );

        } catch {
            $self->logger->error( "Error retrieving nfcapd file listing: " . Dumper($_) );
            sleep(10);
            return;
        };
        my @filepaths = ();
        for(my $i=0; $i<@files; $i++) {
            my $file = $files[$i];
#$self->logger->debug("file: $file");
            my $file_path = dir( $path, $file ) . "";
            my $stats = stat($file_path);
            my $abs = file( $file_path );
            # TODO: changed rel to abs; need a way to figure out a way to convert
            # the old rel paths to abs
            
            my $rel = $abs->relative( $path ) . "";
            if ( exists ( $status->{ $rel } ) ) {
                $status->{ $abs } = $status->{ $rel };
                delete $status->{ $rel };
                #warn "$rel being changed to $abs in file cache ...";
            }
            if ( exists ( $status->{ $abs } ) ) {
                my $entry = $status->{ $abs };
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

        if ( @filepaths > 0 ) {
            my $success = $self->_get_nfdump_data(\@filepaths, %params);
        }




    } # end collections foreach loop


}

sub _get_nfdump_data {
    my ( $self, $flowfiles, %params ) = @_;

    my $sensor = $params{'sensor'};
    my $instance = $params{'instance'};

my $path = $params{'path'};
    
    my $flow_type = $params{'flow_type'};

    my $status = $self->status_cache;

    my $flow_batch_size = $self->flow_batch_size;

    #my $path = $self->flow_path;
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

    my $file_count = 0;
    my $cull_count = $self->cull_count;
    my @all_data = ();
    foreach my $flowfile ( @$flowfiles ) {

        # quit if the process has been told to stop
        if ( !$self->is_running ) {
            $self->logger->debug("Quitting flowfile loop and returning from _get_nfdump_data()");
            return;
        }

        $file_count++;
        if ( $cull_count > 0 && $file_count > 0 && $file_count % $cull_count == 0 ) {
            $self->_cull_flow_files( $path );
        }

        my $stats = stat($flowfile);

        # If file does not exist, skip this file
        if ( !defined $stats ) {
            next;
        }

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
            $row->{'meta'}->{'flow_type'} = $flow_type || 'netflow';
            $row->{'meta'}->{'src_ip'} = $sa;
            $row->{'meta'}->{'src_port'} = $sp;
            $row->{'meta'}->{'dst_ip'} = $da;
            $row->{'meta'}->{'dst_port'} = $dp;
            $row->{'meta'}->{'protocol'} = getprotobynumber( $pr );
            $row->{'meta'}->{'sensor_id'} = $sensor;
            $row->{'meta'}->{'instance_id'} = $instance if $instance ne '';
            $row->{'meta'}->{'src_asn'} = $sas;
            $row->{'meta'}->{'dst_asn'} = $das;
            $row->{'meta'}->{'src_ifindex'} = $in if $in;
            $row->{'meta'}->{'dst_ifindex'} = $out if $out;
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

        # TODO: changed rel to abs; need a way to figure out a way to convert
        # the old rel paths to abs
        my $abs = file( $flowfile );
        #my $rel = $abs->relative( $path ) . "";
        $status->{$abs} = {
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

sub _cull_flow_files {
    my ( $self, $path ) = @_;
    my $status = $self->status_cache;
    #$self->logger->debug( "cache status" . Dumper $status );

    if ( $self->cull_enable < 1 ) {
        $self->logger->debug("not culling files (disabled)");
        return;
    }

    $self->logger->debug("CULLING files (enabled)");


    # see how old files should be (in days)
    my $cull_ttl = $self->cull_ttl;

    my @cache_remove = ();
    my %dirs_to_remove = ();

    while( my ($filename, $attributes) = each %$status ) {
        my $mtime = DateTime->from_epoch( epoch =>  $attributes->{'mtime'} );

        my $dur = DateTime::Duration->new(
            days        => $cull_ttl
        );

        my $dt = DateTime->now;

        if ( DateTime->compare( $mtime,  $dt->subtract_duration( $dur ) ) == -1 ) {
            # Make sure that the file exists, AND that it is under our main
            # flow directory. Just a sanity check to prevent deleting files
            # outside the flow data directory tree.

            my $filepath = $filename;
            my $realpath = "";

            try {
                $realpath = path( $filepath )->realpath;

                my $subsumes = path( $path )->subsumes( $realpath );

                # if the flow path does not subsume the file we're asked to delete,
                # refuse
                if ( !$subsumes ) {
                    $self->logger->error("Tried to delete a file outside the flow path!: " . $realpath . " . filename " . $filename);
                    push @cache_remove, $filename;
                    #next;
                }
            } catch {
                # an error here is not necessarily a problem, could just be the file
                # doesn't exist
                #push @cache_remove, $filename;
                #next;

            };

            #return;

            if ( -f $realpath ) {
                my $parent = path( $realpath )->parent;
                $self->logger->debug("deleting $filepath ...");
                unlink $filepath or $self->logger->error( "Could not unlink $realpath: $!" );
                $dirs_to_remove{ $parent } = 1;
            } else {
                #warn "file does not exist; would delete from cache";

            }
            push @cache_remove, $filename;
        }

    }
    foreach my $file ( @cache_remove ) {
        delete $status->{$file};

    }

    foreach my $dir ( keys %dirs_to_remove ) {
        rmdir $dir;

    }
    $self->_write_cache();

}

sub find_nfcapd {
    my ( $self, $params ) = @_;
    #my $path = $self->flow_path;
    my $path = $params->{'path'};
    my $filepath = $File::Find::name;
    if ( not -f $filepath ) {
        return;

    }
    return if not defined $filepath;
    return if $filepath =~ /nfcapd\.current/;
    return if $filepath =~ /\.nfstat$/;

    my $name = 'nfcapd.*';
    my $relative = path( $filepath )->relative( $path );

    # if min_file_age is '0' then we don't care about file age (this is default)
    if ( $self->min_file_age ne '0' ) {
        if ( $self->get_age( "older", $self->min_file_age, $filepath ) ) {

        } else {
            return;
        }
    }

    push @files, "$relative";



}

sub get_age {
    my ( $self, $criterion, $age, $filename ) = @_;

    my ( $interval, $unit ) = ( $age =~ /^(\d+)([DWMYhms])$/ );
    if ( ! $interval or ! $unit ) {
        return;
    } else {
        my %mapping = (
            "D" => "days",
            "W" => "weeks",
            "M" => "months",
            "Y" => "years",
            "h" => "hours",
            "m" => "minutes",
            "s" => "seconds", );
        #exec( sub {
                         my $dt = DateTime->now;
                         $dt->subtract( $mapping{$unit} => $interval );
                         my $compare_to = $dt->epoch;
                         my $mtime = stat( $filename )->mtime;
                         return $criterion eq "older" ?
                            $mtime < $compare_to :
                            $mtime > $compare_to;
                            #            } );
    }
}


1;
