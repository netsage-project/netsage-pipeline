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
    my $dest_ip_seed = '24.' . ip_byte() . '.' . ip_byte() . '.';
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

