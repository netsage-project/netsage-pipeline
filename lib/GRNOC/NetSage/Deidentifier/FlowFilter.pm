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
    $self->test_simp();
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

    my $router_details = $self->router_details->{'results'};
    # drop all messages if we don't have router derailts from simp
    if ( keys %$router_details < 1 ) {
        $self->_add_dropped_count( @$messages );

        return [];
    }

    my $i = 0;
    my @delete_indices = ();
    foreach my $message ( @$messages ) {
        $self->get_router_details();

        my $import_flow = $self->_filter_flow( $message );
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
    my ( $self, $message ) = @_;

    my $src_ifindex = $message->{'meta'}->{'src_ifindex'};
    my $dst_ifindex = $message->{'meta'}->{'dst_ifindex'};

    my $details = $self->router_details;

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
    my $router = $self->router;

    my $details = $self->router_details;
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
    } else {
        $self->logger->debug( "router NOT found in simp: $router" );

    }

    my $now = time();

    $results->{'ts'} = $now;

    $self->_set_router_details( $results );



}

sub test_simp {
    my ( $self, $message ) = @_;

    my @hosts = (
        "137.164.18.52",
        "137.164.21.3",
        "137.164.20.99",
        "137.164.20.105",
        "137.164.20.106",
        "137.164.20.109",
        "137.164.20.110",
        "137.164.21.17",
        "209.124.178.139"
    );



    my $src_ip = $message->{'meta'}->{'src_ip'};
    my $dst_ip = $message->{'meta'}->{'dst_ip'};
    my $router = $self->router;
    my $src_ifindex = $message->{'meta'}->{'src_ifindex'};
    my $dst_ifindex = $message->{'meta'}->{'dst_ifindex'};

   my $client = $self->simp_client;

   foreach my $host (@hosts ) {
       my %query = (
           node => [$host],
           oidmatch => ["1.3.6.1.2.1.31.1.1.1.18.*"]

       );

       my $results = $client->get( %query );

       if ( exists( $results->{'results'} ) && keys ( %{ $results->{'results'} } ) > 0  ) {
           $self->logger->debug( "FOUND: $host" );
       } else {
           $self->logger->debug( "no results: $host" );
       }
   }

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

