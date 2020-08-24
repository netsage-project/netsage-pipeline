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
use Env;

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
sub getSensorValue()
{
    my $sensor_id = $_[0];
    # check if sensorId value starts with a $ sign, if so get value from env
    if (index($sensor_id, '$') == 0) {
        my $env_var  = substr $sensor_id, 1;  ##chop off the $ sign
        my $env_value =  $ENV{$env_var} || '';
        ## IF the env is set use its value, otherwise fallback on hostname
        if ($env_value  ne '') {
            $sensor_id = $env_value;
        } else {
            $sensor_id = hostname();
        }
    # If the sensor is set to empty string use hostname
    } elsif ($sensor_id eq ""){
        $sensor_id = hostname();
   }

   return $sensor_id;
}


sub BUILD {

    my ( $self ) = @_;

    my $config = $self->config;
    my $sensor_id = &getSensorValue($config->{ 'sensor' } || '');

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

        my $path = $collection->{'flow-path'}; # || $self->flow_path;
        # if path doesn't end with an /, add one. Required for finding @paths_to_check.
        if ( $path !~ /.+\/$/) {
            $path = $path."/";
        }

        my $sensor = &getSensorValue($collection->{'sensor'}  || '');
        $self->logger->info( " Doing collection $sensor ");

        my %params = %{ $self->_get_params( $collection ) };
        $params{'flow-path'} = $path;
        $params{'sensor'} = $sensor;

        my $min_bytes = $self->min_bytes;

        $self->logger->debug("path: $path");
        $self->logger->debug("min_file_age: " . $self->min_file_age );

        $self->_cull_flow_files( $path );

        # We need to compare files to the contents of the cache file to see if they have been imported already.
        # --- If files are not being culled, we don't want to compare every file ever saved, so
        # --- first, narrow down the list of dirs to look through to only those with dates more recent than N months ago.
        my $collection_dir = $path;
        my @paths_to_check;
        if ( $self->cull_enable < 1 ) {
            my $now = DateTime->today;   # UTC (at 00:00:00)
            my $now_yr  = $now->year();
            my $now_mo  = $now->month();
            my $now_day = $now->day();
            my $too_old_date = $now->subtract( months => 2 );  # HARDCODED THRESHOLD N (must be less than the cache file culling threshold!)
            my $too_old_yr  = $too_old_date->year();
            my $too_old_mo  = $too_old_date->month();
            my $too_old_day = $too_old_date->day();

            for (my $yr = $too_old_yr; $yr <= $now_yr ; $yr++) {
                for (my $mo = 1; $mo <= 12; $mo++) {
                    # don't need to continue beyond current month
                    last  if ( $yr == $now_yr and $mo == $now_mo + 1);
                    # If first and last day of month are not too old, we want to look at all files in that month
                    my $first_day = DateTime->new( { year=>$yr, month=>$mo, day=>"01" } );
                    my $last_day  = DateTime->last_day_of_month( { year=>$yr, month=>$mo } );
                    if ( $first_day >= $too_old_date and $last_day > $too_old_date ) {
                        # add dir to list
                        my $subdir = sprintf("%02d/%02d/", $yr, $mo);
                        push (@paths_to_check, $collection_dir.$subdir);
            $self->logger->debug("will check ".$collection_dir.$subdir);
                    }
                    elsif ( $first_day <= $too_old_date and $too_old_date <= $last_day ) {
                        # if $too_old_date is in the middle of the month, go through the day dirs.
                        for (my $day = 1; $day <= $last_day->day(); $day++) {
                           my $day_date  = DateTime->new( { year=>$yr, month=>$mo, day=>$day } );
                           if ( $day_date >= $too_old_date ) {
                               my $subdir = sprintf("%02d/%02d/%02d/", $yr, $mo, $day);
                               push (@paths_to_check, $collection_dir.$subdir);
                   $self->logger->debug("will check ".$collection_dir.$subdir);
                           }
                       }
                   }
               }
           }
        } else {
           # if culling is enabled, it's shouldn't be a big deal to just examine all existing files
           @paths_to_check = ( $collection_dir );
        }


        # Get list of files to compare to cache file contents, exclude files that are too new (< min_file_age)
        try {
            @files = ();
            find({ wanted => sub { find_nfcapd($self, \%params)  }, follow => 1 }, @paths_to_check );

        } catch {
            $self->logger->error( "Error retrieving nfcapd file listing: " . Dumper($_) );
            sleep(10);
            return;
        };

        # Get list of files to actually import by comparing to cache file record of what's been done before
        my @filepaths = ();
        for(my $i=0; $i<@files; $i++) {
            my $file = $files[$i];
            #$self->logger->debug("file: $file");
            my $file_path = dir( $path, $file ) . "";
            my $stats = stat($file_path);
            my $abs = file( $file_path );
            # TODO: changed rel to abs; need a way to figure out a way to convert
            # the old rel paths to abs


            # skip empty files (header and/or footer only). They can cause problems.
            if( ! $stats or ! $stats->size ) {
                $self->logger->info("*** For $path $file, there are no stats!? skipping.");
                next;
            } 
            # elsif( $stats->size <= 420 ) {
            #     $self->logger->debug("skipping $path $file because size is <= 420");
            #     next;
            # }

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

        # Read the nfcapd files to import
        if ( @filepaths > 0 ) {
            my $success = $self->_get_nfdump_data(\@filepaths, %params);

            # --- make cache file smaller.  (sub will do nothing if nfcapd file culling is enabled) (if it is enabled, it will cull the cache file itself.)
            if ($success) {
                $self->logger->debug( "calling cull_cache_file for $sensor");
                $self->_cull_cache_file();
                $self->logger->debug( "done with cull_cache_file for $sensor");
            }
        }


    } # end loop over collections


}

# Loop over files to import, using nfdump to read each. Write cache file after each file is read.
sub _get_nfdump_data {
    my ( $self, $flowfiles, %params ) = @_;

    my $sensor = $params{'sensor'};
    my $instance = $params{'instance'};

    my $path = $params{'path'};  # flow-path

    my $flow_type = $params{'flow_type'};

    my $status = $self->status_cache;

    my $flow_batch_size = $self->flow_batch_size;

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

        $self->logger->info(" importing file: $flowfile");

        my $command = "$nfdump -r '$flowfile'";
    $command .= " -a"; # perform aggregation based on 5 tuples
        $command .= ' -o "fmt:%ts,%te,%td,%sa,%da,%sp,%dp,%pr,%flg,%fwd,%stos,%ipkt,%ibyt,%opkt,%obyt,%in,%out,%sas,%das,%smk,%dmk,%dtos,%dir,%nh,%nhb,%svln,%dvln,%ismc,%odmc,%idmc,%osmc,%mpls1,%mpls2,%mpls3,%mpls4,%mpls5,%mpls6,%mpls7,%mpls8,%mpls9,%mpls10,%ra,%eng,%bps,%pps,%bpp"';
        $command .= ' -6';  # to get full ipv6 addresses
        $command .= ' -L +' . $min_bytes;
        $command .= " -N -q";
        $command .= ' |';
        $self->logger->debug(" command:\n$command\n");

        my $fh;
        open($fh, $command);

        my $i = 0;
        while ( my $line = <$fh> ) {
            my ( $ts,$te,$td,$sa,$da,$sp,$dp,$pr,$flg,$fwd,$stos,$ipkt,$ibyt,$opkt,$obyt,$in,$out,$sas,$das,$smk,$dmk,$dtos,$dir,$nh,$nhb,$svln,$dvln,$ismc,$odmc,$idmc,$osmc,$mpls1,$mpls2,$mpls3,$mpls4,$mpls5,$mpls6,$mpls7,$mpls8,$mpls9,$mpls10,$ra,$eng,$bps,$pps,$bpp ) = split( /\s*,\s*/, $line);

            if ($ts =~ /^Byte/ ) { next; }

            my $start = str2time( $ts );
            my $end   = str2time( $te );

            if ( !defined $start || !defined $end ) {
                $self->logger->error("Invalid line in $flowfile. $!. Start or End time is undefined.");
                $self->logger->error("line: $line");
                $self->logger->error("ts: $ts     start: $start");
                $self->logger->error("te: $te     end: $end");
                next;
            }

            my $sum_bytes = $ibyt + $obyt;
            my $sum_packets = $ipkt + $opkt;
            my $proto = '';
            if( $pr =~ /^\d+$/ ) {
                $proto = getprotobynumber( $pr );
            } else {
                $proto = lc($pr);
            }

            my $row = {};
            # $row->{'type'} = 'flow';
            # $row->{'interval'} = 600;
            # $row->{'meta'} = {};
            # $row->{'meta'}->{'flow_type'} = $flow_type || 'netflow';
            # $row->{'meta'}->{'src_ip'} = $sa;
            # $row->{'meta'}->{'src_port'} = $sp;
            # $row->{'meta'}->{'dst_ip'} = $da;
            # $row->{'meta'}->{'dst_port'} = $dp;
            # $row->{'meta'}->{'protocol'} = $proto;
            # $row->{'meta'}->{'sensor_id'} = $sensor;
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

    } ## end loop over flow files


    if ( $self->run_once ) {
        $self->logger->debug("only running once, stopping");
            $self->_set_is_running( 0 );
    }

    if (!@all_data) {
    # @all_data should be empty. success.
        return 1;
    } else {
    # something went wrong
        return;
    }


};

### private methods ###

sub _write_cache {
    my ( $self ) = @_;
    my $filename = $self->cache_file;
    $self->logger->debug( "writing cache file $filename" );
    my $status = $self->status_cache;
    store $status, $filename;
    $self->logger->debug( "done writing cache file $filename" );

}


sub _read_cache {
    my ( $self ) = @_;
    my $filename = $self->cache_file;
    $self->logger->debug( "reading cache file $filename" );
    my $status = $self->status_cache;
    if ( not -f $filename ) {
        open my $fh, '>', $filename
            or die "Cache file $filename does not exist, and failed to created it: $!\n";
        close $fh;
        store $status, $filename;
    }
    $status = retrieve $filename;
    $self->_set_status_cache( $status );
    $self->logger->debug( "done reading cache file $filename" );
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
    #warn "status " . Dumper $status;
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
                    #$self->logger->debug("Tried to delete a file outside the flow path!: " . $realpath . "; path: " . $path);
                    #push @cache_remove, $filename;
                    #next;
                }
            } catch {
                # an error here is not necessarily a problem, could just be the file
                # doesn't exist
                #push @cache_remove, $filename;
                #next;

            };

            #return;
            #

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

# If culling of nfcapd files is not enabled, the cache file can become huge. This cuts it down to last X months.
sub _cull_cache_file {
    my ( $self ) = @_;

    # If file culling is enabled, that will also cull the cache file, so just return.
    if ( $self->cull_enable == 1 ) {
        $self->logger->debug("not running cull_cache_file");
        return;
    }

    # delete files older than X months (by filename) from the cache file.
    my $cull_to = DateTime->now->subtract( months => 3 );  # UTC datetime    HARDCODED THRESHOLD = 3 mo.
                                                           # Make sure this is > hardcoded threshold in _get_flow_data.
    my $status = $self->status_cache;

    foreach my $key ( keys %$status ) {
        # Key = full path and filename in cache file. Parse filename for date and time
        my ($file_yr, $file_mo, $file_day, $file_hr, $file_min) = $key =~ /.*(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})$/;
        # Make it into a date object
        my $file_date = DateTime->new( year => $file_yr, month => $file_mo, day => $file_day,
                                       hour => $file_hr, minute => $file_min, time_zone => "UTC" );
        # Delete if $file_date < $cull_to
        if ( DateTime->compare($file_date, $cull_to) == -1 ) {
            delete $status->{ $key };
        }
    }

    $self->_set_status_cache( $status );
    $self->_write_cache();
}


sub find_nfcapd {
    my ( $self, $params ) = @_;
    my $path = $params->{'path'};     # flow-path, base dir
    my $filepath = $File::Find::name; # full path+filename
    return if not defined $filepath;
    if ( not -f $filepath ) {
        return;

    }
    return if $filepath =~ /nfcapd\.current/;
    return if $filepath =~ /\.nfstat$/;

    my $name = 'nfcapd.*';
    my $relative = path( $filepath )->relative( $path );

    # if min_file_age is '0' then we don't care about file age (this is default).
    # if not, ignore files younger than min_file_age.
    if ( $self->min_file_age ne '0' ) {
        if ( ! $self->get_age( "older", $self->min_file_age, $filepath ) ) {
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
