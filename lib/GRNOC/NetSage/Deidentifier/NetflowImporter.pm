package GRNOC::NetSage::Deidentifier::NetflowImporter;

use Moo;

use GRNOC::Log;
use GRNOC::Config;

use Net::AMQP::RabbitMQ;
use JSON::XS;
use Math::Round qw( nlowmult nhimult );
use List::MoreUtils qw( natatime );
use Try::Tiny;
use Date::Parse;
use Number::Bytes::Human qw(format_bytes);

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

### constructor builder ###

sub BUILD {

    my ( $self ) = @_;

    # create and store logger object
    my $grnoc_log = GRNOC::Log->new( config => $self->logging_file );
    my $logger = GRNOC::Log->get_logger();

    $self->_set_logger( $logger );

    # create and store config object
    my $config = GRNOC::Config->new( config_file => $self->config_file,
                                     force_array => 0 );

    $self->_set_config( $config );

    my $flow_batch_size =  $self->config->get( '/config/worker/flow-batch-size' );
    warn "flow batch size: $flow_batch_size";

    $self->_set_flow_batch_size( $flow_batch_size );

    return $self;
}

### public methods ###

sub run {

    my ( $self ) = @_;

    $self->logger->debug( "Running." );

    # change our process name
    $0 = "netsage raw netflow importer";

    # create JSON object
    my $json = JSON::XS->new();

    $self->_set_json( $json );

    # connect to rabbit queues
    $self->_rabbit_connect();

    # continually consume messages from rabbit queue, making sure we have to acknowledge them
    #$self->logger->debug( 'Starting RabbitMQ consume loop.' );
    print_memusage();

    my $success = $self->_get_flow_data();

    if ( !$success ) {
        $self->logger->debug('Error retrieving data');
        return;
    }
    $self->logger->debug('Data retrieved; sending to rabbit');
    return $self->_publish_data();

}

sub _get_flow_data {
    my ( $self ) = @_;

    my $flow_batch_size = $self->flow_batch_size;

    my $path = $self->flowpath;
    my $min_bytes = $self->min_bytes;

    my $command = "/usr/bin/nfdump -R $path";
    $command .= ' -o csv -o "fmt:%ts,%te,%td,%sa,%da,%sp,%dp,%pr,%flg,%fwd,%stos,%ipkt,%ibyt,%opkt,%obyt,%in,%out,%sas,%das,%smk,%dmk,%dtos,%dir,%nh,%nhb,%svln,%dvln,%ismc,%odmc,%idmc,%osmc,%mpls1,%mpls2,%mpls3,%mpls4,%mpls5,%mpls6,%mpls7,%mpls8,%mpls9,%mpls10,%ra,%eng,%bps,%pps,%bpp"';
    $command .= ' bytes\>' . $min_bytes;
    $command .= " -N -q";
    #$command .= ' > test.csv ';
    $command .= ' |';
    warn "command:\n\n$command\n\n";
    my $fh;
    open($fh, $command);

    my @all_data = ();

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
        $i++;
        if ( $i % $flow_batch_size == 0 ) {
            warn "processed $flow_batch_size flows; publishing ... ";
            $self->_set_json_data( \@all_data );
            $self->_publish_data();
            @all_data = ();
        }
    }

    #return;

    #my $files = $self->flowpath;

    ## TODO: update
    #foreach my $file ( @$files ) {
    #    my $json_data;
    #    {
    #        local $/; #Enable 'slurp' mode
    #        open my $fh, "<", $file || die ('error loading json file');
    #        $json_data = <$fh>;
    #        close $fh;
    #    }

    #    my $data;
    #    try {
    #        $data = $self->json->decode( $json_data );
    #        push @all_data, @$data;
    #    }
    #    catch {
    #        $self->logger->warn( "Unable to JSON decode message: $_" );
    #    };
    #}
    $self->_set_json_data( \@all_data );

    warn "remaining floows: " . @all_data;

    if (!@all_data) {
        return;
    } else {
        return 1;
    }

};

### private methods ###

sub _publish_data {
    my ( $self ) = @_;
    if ( !$self->json_data ) {
        $self->logger->info("No data found to publish");
        return;
    }
    my $data = $self->json_data;

    # send a max of 100 messages at a time to rabbit
    my $it = natatime( 100, @$data );

    #my $queue = $self->config->get( '/config/rabbit/raw-queue' );
    my $rabbit_conf = $self->config->get( '/config/rabbit' );
    my $queue = $rabbit_conf->{'queue'}->{'raw'}->{'rabbit_name'};

    while ( my @finished_messages = $it->() ) {
        warn "publishing " . @finished_messages . " messsages";

        $self->rabbit->publish( RAW_FLOWS_QUEUE_CHANNEL, $queue, $self->json->encode( \@finished_messages ), {'exchange' => ''} );

    }
    print_memusage();
    $self->_set_json_data( () );

}


sub _rabbit_connect {

    my ( $self ) = @_;

    my $rabbit_host = $self->config->get( '/config/rabbit/host' );
    my $rabbit_port = $self->config->get( '/config/rabbit/port' );
    my $rabbit_username = $self->config->get( '/config/rabbit/username' );
    my $rabbit_password = $self->config->get( '/config/rabbit/password' );
    my $rabbit_vhost = $self->config->get( '/config/rabbit/vhost' );
    my $rabbit_ssl = $self->config->get( '/config/rabbit/ssl' ) || 0;
    my $rabbit_ca_cert = $self->config->get( '/config/rabbit/cacert' );
    my $rabbit_conf = $self->config->get( '/config/rabbit' );
    my $raw_data_queue = $rabbit_conf->{'queue'}->{'raw'}->{'rabbit_name'};
    while ( 1 ) {

        $self->logger->info( "Connecting to RabbitMQ $rabbit_host:$rabbit_port." );

        my $connected = 0;

        try {

            my $rabbit = Net::AMQP::RabbitMQ->new();

            my $params = {};
            $params->{'port'} = $rabbit_port;
            $params->{'user'} = $rabbit_username;
            $params->{'password'} = $rabbit_password;
            if ( $rabbit_ssl ) {
                $params->{'ssl'} = $rabbit_ssl;
                $params->{'ssl_verify_host'} = 0;
                $params->{'ssl_cacert'} = $rabbit_ca_cert;
            }
            if ( $rabbit_vhost ) {
                $params->{'vhost'} = $rabbit_vhost;
            }

            $rabbit->connect( $rabbit_host, $params  );


	    # open channel to the pending queue we'll read from
            $rabbit->channel_open( RAW_FLOWS_QUEUE_CHANNEL );
            $rabbit->queue_declare( RAW_FLOWS_QUEUE_CHANNEL, $raw_data_queue, {'auto_delete' => 0} );
            $rabbit->basic_qos( RAW_FLOWS_QUEUE_CHANNEL, { prefetch_count => QUEUE_PREFETCH_COUNT } );

            $self->_set_rabbit( $rabbit );

            $connected = 1;
        }

        catch {

            $self->logger->error( "Error connecting to RabbitMQ: $_" );
        };

        last if $connected;

        $self->logger->info( "Reconnecting after " . RECONNECT_TIMEOUT . " seconds..." );
        sleep( RECONNECT_TIMEOUT );
    }
}

sub print_memusage {
    my @usage = get_memusage(@_);
    warn "Usage: " . format_bytes($usage[0], bs => 1000) . "; " . $usage[1] . "%";
    return \@usage;
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
