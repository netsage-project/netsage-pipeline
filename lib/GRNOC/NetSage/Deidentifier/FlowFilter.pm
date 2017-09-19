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

### constructor builder ###

sub BUILD {

    my ( $self ) = @_;

    my $config_obj = $self->config;
    my $config = $config_obj->get('/config');
    warn "config: " . Dumper $config;
    #my $anon = $config->{'deidentification'};
    #my $ipv4_bits = $config->{'deidentification'}->{'ipv4_bits_to_strip'};
    #my $ipv6_bits = $config->{'deidentification'}->{'ipv6_bits_to_strip'};
    #$self->_set_ipv4_bits_to_strip( $ipv4_bits );
    #$self->_set_ipv6_bits_to_strip( $ipv6_bits );
    $self->_set_handler( sub { $self->_filter_messages(@_) } );
    $self->_connect_simp();

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
        my $src_ip = $message->{'meta'}->{'src_ip'};
        my $dst_ip = $message->{'meta'}->{'dst_ip'};
        my $src_ifindex = $message->{'meta'}->{'src_ifindex'};
        my $dst_ifindex = $message->{'meta'}->{'dst_ifindex'};

        # perform a couple other necessary manipulations
        warn " message: " . Dumper $message if $tmp == 0;
        $tmp++;
    }

    return $finished_messages;
}

sub _compare_flows {
    my ( $self, $message ) = @_;

    my $src_ip = $message->{'meta'}->{'src_ip'};
    my $dst_ip = $message->{'meta'}->{'dst_ip'};
    my $src_ifindex = $message->{'meta'}->{'src_ifindex'};
    my $dst_ifindex = $message->{'meta'}->{'dst_ifindex'};

   my $client = $self->simp_client;


   my $results = $client->get(
         node => [$src_ip, $dst_ip],
         #node => ["wrn-elpa-sw-1.cenic.net"],
         #node    =>  ["cmsstor613.fnal.gov", "cabinet-1-1-30.t2.ucsd.edu", "macrobius.cs.nmt.edu"],
         #node   => ["156.56.6.103","156.56.6.108"],
         oidmatch => ["1.3.6.1.2.1.2.2.1.2", "1.3.6.1.2.1.31.1.1.1.18"]
         #oidmatch => ["1.3.6.1.2.1.31.1.1.1.18.*"]

  );

  print Dumper($results)


}

sub _connect_simp {
    my ( $self ) = @_;
    my $client = GRNOC::RabbitMQ::Client->new(
        #host => "127.0.0.1",
        host => "simp.bldc.grnoc.iu.edu",
        port => 5672,
        user => "guest",
        pass => "guest",
        exchange => 'Simp',
        timeout => 60,
        topic => 'Simp.Data');
    $self->simp_client( $client );
}

1;

