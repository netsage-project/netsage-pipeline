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

has simp_client => ( is => 'rwp');

has router => ( is => 'rwp');

has router_details => ( is => 'rwp');

### constructor builder ###

sub BUILD {

    my ( $self ) = @_;

    my $config_obj = $self->config;
    my $config = $config_obj->get('/config');
    warn "config: " . Dumper $config;
    my $router = $config->{'worker'}->{'router-address'};
    $self->_set_router( $router );
    $self->_set_handler( sub { $self->_filter_messages(@_) } );
    $self->_connect_simp();
    #$self->test_simp();
    $self->get_router_details();

    return $self;
}

### private methods ###

# expects an array of data for it to filter
# returns the filtered array
sub _filter_messages {
    my ( $self, $caller, $messages ) = @_;

    my $finished_messages = $messages;

    my $tmp = 0;
    foreach my $message ( @$messages ) {

        $self->compare_flows( $message );

        # perform a couple other necessary manipulations
        #warn " message: " . Dumper $message if $tmp == 0;
        $tmp++;
    }

    return $finished_messages;
}

sub compare_flows {
    my ( $self, $message ) = @_;

    #warn "comparing flows ";

    my $src_ifindex = $message->{'meta'}->{'src_ifindex'};
    my $dst_ifindex = $message->{'meta'}->{'dst_ifindex'};



    my $details = $self->router_details;

    #warn "details " . Dumper $details;
    warn "src_ifindex: $src_ifindex; dst_ifindex: $dst_ifindex";

    warn "results " . Dumper $details->{'results'};
    warn "ref results " . ref $details->{'results'};
    my $host = ( keys ( %{ $details->{'results'} } ) )[0];
    warn "host: " . Dumper $host;

    my $mib_base = "1.3.6.1.2.1.31.1.1.1.18";
    my $src_key = "$mib_base.$src_ifindex";
    my $dst_key = "$mib_base.$dst_ifindex";

    my $src_description = $details->{ 'results' }->{ $host }->{ $src_key }->{ 'value' };
    my $dst_description = $details->{ 'results' }->{ $host }->{ $dst_key }->{ 'value' };

    warn "src_description: $src_description";
    warn "dst_description: $dst_description";

    # TODO: see if description contains [ns-exp]
    
    if ( $src_description =~ /\[ns-exp\]/ ) {
        warn "IMPORTING src: $src_ifindex!";
    } else {
        warn "SKIPPING src: $src_ifindex!";

    }
    if ( $dst_description =~ /\[ns-exp\]/ ) {
        warn "IMPORTING dst: $dst_ifindex!";
    } else {
        warn "SKIPPING dst: $dst_ifindex!";

    }





}

sub get_router_details {
    my ( $self ) = @_;

    my $client = $self->simp_client;
    my $router = $self->router;

    warn "querying simp for router $router ...";

    my %query = (
        node => [$router],
        #node => [$src_ip, $dst_ip],
        #node => ["wrn-elpa-sw-1.cenic.net", "cmsstor613.fnal.gov"],
        #node => ["137.164.20.99"], # wrn-elpa-sw-1.cenic.net
        #node    =>  ["cmsstor613.fnal.gov", "cabinet-1-1-30.t2.ucsd.edu", "macrobius.cs.nmt.edu"],
        #node   => ["156.56.6.103","156.56.6.108"],
        #oidmatch => ["1.3.6.1.2.1.2.2.1.2", "1.3.6.1.2.1.31.1.1.1.18"]
        oidmatch => ["1.3.6.1.2.1.31.1.1.1.18.*"]
        #oidmatch => ["*"]

    );
    #warn "query " . Dumper \%query;

    my $results = $client->get( %query );

    if ( exists( $results->{'results'} ) && %{ $results->{'results'} }  ) {
        #warn "simp results: " . Dumper($results);\
        warn "router found: $router";
    }

    $self->_set_router_details( $results );



}

sub test_simp {
    my ( $self, $message ) = @_;

    #warn "comparing flows ";
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

   warn "querying simp for hosts  ... " . Dumper \@hosts;

   foreach my $host (@hosts ) {
       my %query = (
           node => [$host],
           #node => \@hosts,
           #node => [$src_ip, $dst_ip],
           #node => ["wrn-elpa-sw-1.cenic.net", "cmsstor613.fnal.gov"],
           #node => ["137.164.20.99"], # wrn-elpa-sw-1.cenic.net
           #node    =>  ["cmsstor613.fnal.gov", "cabinet-1-1-30.t2.ucsd.edu", "macrobius.cs.nmt.edu"],
           #node   => ["156.56.6.103","156.56.6.108"],
           #oidmatch => ["1.3.6.1.2.1.2.2.1.2", "1.3.6.1.2.1.31.1.1.1.18"]
           oidmatch => ["1.3.6.1.2.1.31.1.1.1.18.*"]
           #oidmatch => ["*"]

       );
       #warn "query " . Dumper \%query;

       my $results = $client->get( %query );

       if ( exists( $results->{'results'} ) && %{ $results->{'results'} }  ) {
           #warn "simp results: " . Dumper($results);
            warn "FOUND: $host";
       } else {
           warn "no results: $host";
       }
   }

}

sub _connect_simp {
    my ( $self ) = @_;
    warn "connecting to simp ...";
    my $client = GRNOC::RabbitMQ::Client->new(
        #host => "127.0.0.1",
        host => "simp.bldc.grnoc.iu.edu",
        port => 5672,
        user => "guest",
        pass => "guest",
        exchange => 'Simp',
        timeout => 60,
        topic => 'Simp.Data');
    $self->_set_simp_client( $client );
    warn "done";
    return $client;
}

1;

