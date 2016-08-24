package GRNOC::NetSage::Deidentifier::NetflowImporter;

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
use Number::Bytes::Human qw(format_bytes);
use File::stat;
use File::Find::Rule;
use File::Find::Rule::Age;
use Path::Class;
use Storable qw( store retrieve );

use Data::Dumper;

### constants ###

use constant QUEUE_PREFETCH_COUNT => 20;
use constant QUEUE_FETCH_TIMEOUT => 10 * 1000;
use constant RECONNECT_TIMEOUT => 10;
use constant RAW_FLOWS_QUEUE_CHANNEL => 1;

### required attributes ###

has config_file => ( is => 'ro',
                required => 1 );

has logging_file => ( is => 'ro',
                      required => 1 );

has flowpath => ( is => 'ro',
                      required => 1 );


### internal attributes ###

has logger => ( is => 'rwp' );

has config => ( is => 'rwp' );

has is_running => ( is => 'rwp',
                    default => 0 );

has rabbit => ( is => 'rwp' );

has json => ( is => 'rwp' );

has json_data => ( is => 'rwp' );

has status => ( is => 'rwp' );

has min_bytes => ( is => 'rwp',
                   default => 500000000 ); # 500 MB

has flow_batch_size => ( is => 'rwp' );

has latest_ts => ( is => 'rwp',
                   default => 0 );

has import_status => ( is => 'rwp',
                       default => sub { {} } );

has cache_file => ( is => 'rwp',
                    default => '/var/cache/netsage/netflow_importer.cache' );

### constructor builder ###

sub BUILD {

    my ( $self ) = @_;

    my $config_obj = $self->config;
    my $config = $config_obj->get('/config');

    # warn "config: " . Dumper $config;
    my $flow_batch_size =  $config->{'worker'}->{'flow-batch-size'};
    warn "flow batch size: $flow_batch_size";

    $self->_set_flow_batch_size( $flow_batch_size );
    $self->_set_handler( sub{ $self->_run_netflow_import(@_) } );

    # create JSON object
    my $json = JSON::XS->new();

    $self->_set_json( $json );

    $self->_read_cache();

    return $self;
}

### public methods ###

sub _run_netflow_import {

    my ( $self ) = @_;


    # connect to rabbit queues
    #$self->_rabbit_connect();

    # continually consume messages from rabbit queue, making sure we have to acknowledge them
    #$self->logger->debug( 'Starting RabbitMQ consume loop.' );
    print_memusage();

    my $success = $self->_get_flow_data();

    #if ( !$success ) {
    #    $self->logger->debug('Error retrieving data');
    #    return;
    #}
    #$self->logger->debug('Data retrieved; sending to rabbit');
    return $self->_publish_flows();

}

sub _get_flow_data {
    my ( $self ) = @_;

    my $flow_batch_size = $self->flow_batch_size;
    my $status = $self->import_status;

    my $path = $self->flowpath;
    my $min_bytes = $self->min_bytes;

    warn "path: $path";
    my @years = $self->_get_dirs( $path );
    warn "years: " . Dumper @years;

    my $ts_template = '%Y/%m/%d.%H:%M:%S';

    foreach my $year ( @years ) {
        warn "year relative combined: " . dir( $path, $year);
        my $year_path = dir( $path, $year );
        my $stats = stat($year_path);
        warn "mtime: " . $stats->mtime . " " . time2str( $ts_template, $stats->mtime );
        warn "size: " . $stats->size;
        warn "stats: " . Dumper $stats;

        my @months = $self->_get_dirs( $year_path );

        warn "months: " . Dumper @months;

        foreach my $month (@months) {
            my $month_path = dir( $year_path, $month );
            warn "month relative combined: $month_path";
            my @days = $self->_get_dirs( $month_path );
            warn "days: " . Dumper @days;

            foreach my $day ( @days ) {
                my $day_path = dir( $month_path, $day );
                my @files = File::Find::Rule
                    ->file()
                    ->maxdepth(1)
                    ->age( 'older', '1D' )
                    ->name( 'nfcapd.*' )
                    ->relative(1)
                    ->in($day_path);
                my @filepaths = ();
                for(my $i=0; $i<@files; $i++) {
                    my $file = $files[$i];
                    my $file_path = dir( $day_path, $file ) . "";
                    my $stats = stat($file_path);
                    my $abs = file( $file_path );
                    my $rel = $abs->relative( $path ) . "";
                    #warn "rel: " . Dumper $rel;
                    if ( exists ( $status->{ $rel } ) ) {
                        my $entry = $status->{ $rel };
                        #warn "entry: " . Dumper $entry;
                        my $mtime_cache = $entry->{'mtime'};
                        my $size_cache  = $entry->{'size'};
                        #warn "mtime_cache: " . Dumper $mtime_cache;
                        #warn "size_cache: " . Dumper $size_cache;
                        if ( $mtime_cache == $stats->mtime
                            && $size_cache == $stats->size ) {
                            next;
                        }
                    }
                    push @filepaths, dir( $day_path, $file ) . "";

                }
                #@files = sort @files;
                @filepaths = sort @filepaths;
                warn "filepaths: " . Dumper @filepaths;
                #warn "files: " . Dumper @files;
                my $success = $self->_get_nfdump_data(\@filepaths);
                #return $success;

            }

        }
    }
}

sub _get_nfdump_data {
    my ( $self, $flowfiles ) = @_;


    my $status = $self->import_status;
    #warn "get_nfdump status: " . Dumper $status;

    my $flow_batch_size = $self->flow_batch_size;

    my $path = $self->flowpath;
    my $min_bytes = $self->min_bytes;

    my @all_data = ();
    foreach my $flowfile ( @$flowfiles ) {
        my $stats = stat($flowfile);

        my $command = "/usr/bin/nfdump -R '$flowfile'";
        $command .= ' -o csv -o "fmt:%ts,%te,%td,%sa,%da,%sp,%dp,%pr,%flg,%fwd,%stos,%ipkt,%ibyt,%opkt,%obyt,%in,%out,%sas,%das,%smk,%dmk,%dtos,%dir,%nh,%nhb,%svln,%dvln,%ismc,%odmc,%idmc,%osmc,%mpls1,%mpls2,%mpls3,%mpls4,%mpls5,%mpls6,%mpls7,%mpls8,%mpls9,%mpls10,%ra,%eng,%bps,%pps,%bpp"';
        #$command .= ' -t ' . time2str($ts_template, $latest_ts) if $latest_ts > 0;
        $command .= ' bytes\>' . $min_bytes;
        $command .= " -N -q";
        #$command .= ' > test.csv ';
        $command .= ' |';
        warn "command:\n\n$command\n\n";
        my $fh;
        open($fh, $command);


        #return;
        my $i = 0;
        while ( my $line = <$fh> ) {
            my ( $ts,$te,$td,$sa,$da,$sp,$dp,$pr,$flg,$fwd,$stos,$ipkt,$ibyt,$opkt,$obyt,$in,$out,$sas,$das,$smk,$dmk,$dtos,$dir,$nh,$nhb,$svln,$dvln,$ismc,$odmc,$idmc,$osmc,$mpls1,$mpls2,$mpls3,$mpls4,$mpls5,$mpls6,$mpls7,$mpls8,$mpls9,$mpls10,$ra,$eng,$bps,$pps,$bpp ) = split( /\s*,\s*/, $line);

            my $start = str2time( $ts );
            my $end   = str2time( $te );

            if ( !defined $start || !defined $end ) {
                die "Invalid line!: $!";
                next;
            }

            my $sum_bytes = $ibyt + $obyt;
            my $sum_packets = $ipkt + $opkt;

            my $row = {};
            $row->{'type'} = 'flow';
            $row->{'interval'} = 600;
            $row->{'meta'} = {};
            $row->{'meta'}->{'src_ip'} = $sa;
            $row->{'meta'}->{'src_port'} = $sp;
            $row->{'meta'}->{'dst_ip'} = $da;
            $row->{'meta'}->{'dst_port'} = $dp;
            $row->{'meta'}->{'protocol'} = $pr;
            $row->{'start'} = $start;
            $row->{'end'} = $end;

            $row->{'values'} = {};
            $row->{'values'}->{'duration'} = $td;
            $row->{'values'}->{'num_bits'} = $sum_bytes * 8;
            $row->{'values'}->{'num_packets'} = $sum_packets;
            $row->{'values'}->{'bits_per_second'} = $bps;
            $row->{'values'}->{'packets_per_second'} = $pps;
            $row->{'values'}->{'src_asn'} = $sas;
            $row->{'values'}->{'dst_asn'} = $das;

            #warn "row: " . Dumper $row;

            push @all_data, $row;
            if ( @all_data % $flow_batch_size == 0 ) {
                warn "processed " . @all_data . " (up to $flow_batch_size) flows; publishing ... ";
                $self->_set_json_data( \@all_data );
                $self->_publish_flows();
                @all_data = ();
            }
        }
        # publish any remaining data
        $self->_set_json_data( \@all_data );
        $self->_publish_flows();
        @all_data = ();

        #warn "mtime: " . $stats->mtime . " " . time2str( $ts_template, $stats->mtime );
        #warn "size: " . $stats->size;
        my $abs = file( $flowfile );
        my $rel = $abs->relative( $path ) . "";
        $status->{$rel} = {
            mtime => $stats->mtime,
            size => $stats->size
        };
        $self->_set_import_status( $status );
        warn "status: " . Dumper sort keys( %$status );
        $self->_write_cache();
    }

    warn "remaining floows: " . @all_data;

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
    my $status = $self->import_status;
    store $status, $filename;

}


sub _read_cache {
    my ( $self ) = @_;
    my $filename = $self->cache_file;
    my $status = $self->import_status;
    if ( not -f $filename ) {
        open my $fh, '>', $filename
            or die "Cache file $filename does not exist, and failed to created it: $!\n";
        close $fh;
        store $status, $filename;
    }
    $status = retrieve $filename;
    $self->_set_import_status( $status );

}
sub _publish_flows {
    my $self = shift;
    my $flows = $self->json_data;
    #warn "publishing flows ... " . @$flows;
    #warn "flows: " . Dumper $flows;
    # TODO: fix an issue where flows aren't deleted after being published
    if ( defined $flows ) {
        $self->_publish_data( $flows );
    }

    $self->_set_json_data( [] );
}

sub _get_dirs {
    my ( $self, $path ) = @_;

    warn "_get_dirs path: $path";
    my @dirs = File::Find::Rule
        ->directory()
        ->maxdepth(1)
        ->relative(1)
        ->not( File::Find::Rule->new->name(qr/^\.\.?$/) )
        ->in($path);

    warn "dirs: " . Dumper @dirs;

    return @dirs;
}

sub print_memusage {
    my @usage = get_memusage(@_);
    warn "Usage: " . format_bytes($usage[0], bs => 1000) . "; " . $usage[1] . "%";
    return \@usage;
}

sub _update_latest_ts {
    my ( $self, $ts1 ) = @_;
    my $ts2 = $self->latest_ts;
    my $latest = ( $ts1 > $ts2 ? $ts1 : $ts2 );
    $self->_set_latest_ts( $latest );
    return $latest;
}

sub get_memusage {
    use Proc::ProcessTable;
    my @results;
    my $pid = (defined($_[0])) ? $_[0] : $$;
    my $proc = Proc::ProcessTable->new;
    my %fields = map { $_ => 1 } $proc->fields;
    return undef unless exists $fields{'pid'};
    foreach (@{$proc->table}) {
        if ($_->pid eq $pid) {
            push (@results, $_->size) if exists $fields{'size'};
            push (@results, $_->pctmem) if exists $fields{'pctmem'};
        };
    };
    return @results;
}

1;
