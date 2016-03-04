#!/usr/bin/perl

use Data::Dumper;
use Template;
use strict;
use warnings;
use constant NUM_ENTRIES => 200;
use JSON::XS;

my $tt = Template->new();

my @data = ();

for(my $i=0; $i<NUM_ENTRIES; $i++) {
    my ($src_ip, $dest_ip, $src_port, $dest_port, $src_asn, $dest_asn, $node_name);
    my ($src_interface_snmp_index, $dest_interface_snmp_index);
    my ($ip_protocol, $num_bits, $num_packets, $start_time, $end_time);    
    my %row = ();

    my $src_ip_seed = '192.168.0.';
    #my $dest_ip_seed = '24.' . ip_byte() . '.' . ip_byte() . '.';
    my $dest_ip_seed = '140.182.' . ip_byte() . '.';
    $src_ip = $src_ip_seed . ( $i + 1 );

    for(my $j=0; $j<3; $j++) {
        %row = ();
        $dest_ip = $dest_ip_seed . ip_byte();
        $src_port = random_in_range(1, 10000);
        $dest_port = random_in_range(1, 10000);
        $src_asn = asn();
        $dest_asn = asn();

        $end_time = time() - random_in_range(0, 600);
        $start_time = $end_time - random_in_range(0, 86400);

        $row{'src_ip'} = $src_ip;
        $row{'dest_ip'} = $dest_ip;
        $row{'src_port'} = $src_port;
        $row{'dest_port'} = $dest_port;
        $row{'src_asn'} = $src_asn;
        $row{'dest_asn'} = $dest_asn;
        $row{'start_time'} = $start_time;        
        $row{'end_time'} = $end_time;        

        my %row2 = %row;

        push @data, \%row2;
    }

    # real ipv4 addresses
    my %real_ip = ();
    $real_ip{'src_ip'} = '129.79.9.75';
    $real_ip{'dest_ip'} = '140.182.44.196';
    $end_time = time() - random_in_range(0, 600);
    $start_time = $end_time - random_in_range(0, 86400);
    $real_ip{'start_time'} = $start_time;
    $real_ip{'end_time'} = $end_time;
    push @data, \%real_ip;

    %real_ip = ();
    $real_ip{'src_ip'} = '216.58.216.206'; # google
    $real_ip{'dest_ip'} = '198.128.153.23'; # esnet
    $end_time = time() - random_in_range(0, 600);
    $start_time = $end_time - random_in_range(0, 86400);
    $real_ip{'start_time'} = $start_time;
    $real_ip{'end_time'} = $end_time;
    push @data, \%real_ip;

    # Manually add a few ipv6 addresses in different forms
    # These 3 are actually all the same address:
    my @srcs = ( '2001:0db8:85a3:0000:0000:8a2e:0370:7334',
                 '2001:db8:85a3:0:0:8a2e:370:7334',
                 '2001:db8:85a3::8a2e:370:7334',
                 '2001:0db8:85a3:0000:0000:8a2e:0370:7335', # incremented by 1
             );
    my @dests = (
    # perfsonar-dev
    '2001:18e8:3:10:8000::1',
    'fe80::5652:ff:fe2d:7a0a',
    # mac
    'fe80::6a5b:35ff:fe9f:d783',
    '2001:18e8:2:1009:f000::1e0',
    );

    for(my $i=0; $i<@srcs; $i++) {
        %row = ();
        $row{'src_ip'} = $srcs[$i];
        $row{'dest_ip'} = $dests[$i];
        my %row2 = %row;
        $end_time = time() - random_in_range(0, 600);
        $start_time = $end_time - random_in_range(0, 86400);
        $row2{'start_time'} = $start_time;
        $row2{'end_time'} = $end_time;
        push @data, \%row2;
    }
}

#warn Dumper @data;

sub asn {
    return random_in_range(0, 4294967295);
}

sub ip_byte {
    return random_in_range( 1, 255 );
}

sub random_in_range {
    my ( $min, $max) = @_;
    my $ret = $min + int(rand($max - $min)) + 1;
    return $ret;
}

my $vars = {
    data => \@data,
};

#$tt->process( 'templates/netflow_template.tmpl', $vars );

my $json = JSON::XS->new();
print $json->encode( \@data );

