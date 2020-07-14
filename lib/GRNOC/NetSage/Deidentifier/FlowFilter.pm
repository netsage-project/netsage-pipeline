package GRNOC::NetSage::Deidentifier::FlowFilter;

use strict;
use warnings;

use Moo;

extends 'GRNOC::NetSage::Deidentifier::Pipeline';

use GRNOC::Log;
use GRNOC::Config;
use GRNOC::RabbitMQ::Client;

use AnyEvent;
use Data::Validate::IP;
use Net::IP;
use Digest::SHA;
use POSIX;
use utf8;

use Data::Dumper;


### internal attributes ###

has handler => ( is => 'rwp');

has simp_config => ( is => 'rwp' );

has simp_client => ( is => 'rwp');

has router => ( is => 'rwp');

has router_details => ( is => 'rwp', default => sub { {} } );

has snmp_cache_time => ( is => 'rwp', default => 3600 );

has stats => ( is => 'rwp', default => sub { {
    dropped => 0,
    imported => 0
} } );

### constructor builder ###

sub BUILD {

    my ( $self ) = @_;

    my $config = $self->config;
    my $router = $config->{'worker'}->{'router-address'};
    $self->_set_router( $router );
    $self->_set_simp_config( $config->{'simp'} );
    $self->_set_handler( sub { $self->_filter_messages(@_) } );
    $self->_connect_simp();
    $self->get_router_details();

    my $snmp_cache_time = $config->{'worker'}->{'snmp-cache-time'};
    $self->_set_snmp_cache_time( $snmp_cache_time ) if defined $snmp_cache_time;

    return $self;
}

### private methods ###

# expects an array of data for it to filter
# returns the filtered array
sub _filter_messages {
    my ( $self, $caller, $messages ) = @_;

    my $finished_messages = $messages;

    my $router_details = $self->router_details;
    # drop all messages if we don't have router derailts from simp
    if ( keys %$router_details < 1 ) {
        $self->_add_dropped_count( @$messages );

        return [];
    }

    my $i = 0;
    my @delete_indices = ();
    foreach my $message ( @$messages ) {
        my $sensor = $message->{'meta'}->{'sensor_id'};
        my $details = $router_details->{ $sensor };

        my $import_flow = $self->_filter_flow( $message, $details );
        if ( $import_flow < 1 ) {
            push @delete_indices, $i;
            $self->_add_dropped_count( 1 );
        }
        $i++;
    }

    # remove all the deleted indices
    splice @$finished_messages, $_, 1 for reverse @delete_indices;

    $self->_add_imported_count( scalar @$finished_messages );

    $self->logger->debug( "stats " . Dumper $self->stats );

    return $finished_messages;
}

sub _filter_flow {
    my ( $self, $message, $details ) = @_;

    return 0 if !defined ($details) || !defined( $details->{'results'} ) || keys %{ $details->{'results'} } == 0;

    my $src_ifindex = $message->{'meta'}->{'src_ifindex'};
    my $dst_ifindex = $message->{'meta'}->{'dst_ifindex'};

    if (! defined $dst_ifindex or ! defined $src_ifindex ) {
        $self->logger->warn("Missing an ifindex!? Skipping flow.". $message->{'meta'}->{'sensor_id'});
        return 0;
    }

    my $num_results = keys ( %{ $details->{'results'} } );

    return 0 if $num_results < 1;

    my $host = ( keys ( %{ $details->{'results'} } ) )[0];

    my $mib_base = "1.3.6.1.2.1.31.1.1.1.18";
    my $src_key = "$mib_base.$src_ifindex";
    my $dst_key = "$mib_base.$dst_ifindex";

    my $src_description = $details->{ 'results' }->{ $host }->{ $src_key }->{ 'value' } || "";
    my $dst_description = $details->{ 'results' }->{ $host }->{ $dst_key }->{ 'value' } || "";


    # see if src OR dst description contains [ns-exp]

    my $import = 0;

    if ( $src_description =~ /\[ns-exp\]/ ) {
        $self->logger->debug( "IMPORTING src: $src_ifindex!" );
        $import = 1;
    } else {
        $self->logger->debug( "SKIPPING src: $src_ifindex!" );
    }

    if ( $dst_description =~ /\[ns-exp\]/ ) {
        $self->logger->debug( "IMPORTING dst: $dst_ifindex!" );
        $import = 1;
    } else {
        $self->logger->debug( "SKIPPING dst: $dst_ifindex!" );

    }

    return $import;

}

sub get_router_details {
    my ( $self ) = @_;

    my $client = $self->simp_client;

    my $router_details = $self->router_details || {};

    my $collections = $self->config->{'collection'};

    if ( ref($collections) ne "ARRAY" ) {
        $collections = [ $collections ];

    }

    foreach my $collection (@$collections) {

        #my $router = $self->router;
        my $sensor = $collection->{'sensor'};
        my $router = $collection->{'sensor'};
        $router = $collection->{'router-address'} if $collection->{'router-address'};

        my $row = {};

        my $details = $router_details->{'router'};
        if ( defined $details->{'ts'} ) {
            if ( time() - $details->{'ts'} <= $self->snmp_cache_time ) {
                return;
            }
        }

        my %query = (
            node => [$router],
            oidmatch => ["1.3.6.1.2.1.31.1.1.1.18.*"]

        );

        my $results = $client->get( %query );

        if ( exists( $results->{'results'} ) && %{ $results->{'results'} }  ) {
            $self->logger->debug( "router found: $router" );
            $row->{'results'} = $results->{'results'};
            $self->logger->debug( "router found in simp: " . Dumper $results->{'results'} );
        } else {
            $self->logger->warn( "router NOT found in simp: " . Dumper $router );
            $row->{'results'} = undef;

        }

        my $now = time();

        $row->{'ts'} = $now;

        $router_details->{ $sensor } = $row;
    }

    $self->_set_router_details( $router_details );


}

sub _add_dropped_count {
    my ( $self, $num ) = @_;
    $self->_update_stats( {
            dropped => $num
    });

}

sub _add_imported_count {
    my ( $self, $num ) = @_;
    $self->_update_stats( {
            imported => $num
    });

}

sub _update_stats {
    my ( $self, $update ) = @_;
    my $stats = $self->stats;
    my $dropped = $stats->{'dropped'};
    my $imported = $stats->{'imported'};
    if ( $update->{'dropped'} ) {
        $dropped += $update->{'dropped'};
    }
    if ( $update->{'imported'} ) {
        $imported += $update->{'imported'};
    }

    $stats->{'dropped'} = $dropped;
    $stats->{'imported'} = $imported;

    $self->_set_stats( $stats );
}


sub _connect_simp {
    my ( $self ) = @_;

    my $simp = $self->simp_config;

    my $host        = $simp->{'host'};
    my $port        = $simp->{'port'} || 5672;
    my $user        = $simp->{'username'} || "guest";
    my $pass        = $simp->{'password'} || "guest";
    my $exchange    = $simp->{'exchange'} || "Simp";
    my $timeout     = $simp->{'timeout'} || 60;
    my $topic       = $simp->{'topic'} || "Simp.Data";

    my $client = GRNOC::RabbitMQ::Client->new(
        host => $host,
        port => $port,
        user => $user,
        pass => $pass,
        exchange => $exchange,
        timeout => $timeout,
        topic => $topic);
    $self->_set_simp_client( $client );
    return $client;
}

1;

