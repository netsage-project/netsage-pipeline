#!/usr/bin/perl

use strict;
use warnings;
use Number::Bytes::Human qw(format_bytes);
use Time::Duration;
use Data::Dumper;
use JSON::XS;
use Date::Parse;

my @size_buckets = (
	100 * 10**6, # 100 MB,
	200 * 10**6, # 200 MB
	300 * 10**6, # 300 MB
	400 * 10**6, # 400 MB
	500 * 10**6, # 500 MB
	600 * 10**6, # 600 MB
	700 * 10**6, # 700 MB
	800 * 10**6, # 800 MB
	900 * 10**6, # 900 MB
	1 * 10**9, # 1 GB
	2 * 10**9, # 2 GB
	3 * 10**9, # 3 GB
	4 * 10**9, # 4 GB
	5 * 10**9, # 5 GB
	10 * 10**9, # 10 GB
	100 * 10**9, # 100 GB
	1 * 10**12, # 1 TB
	10 * 10**12, # 10 TB
	100 * 10**12, # 100 TB
);

my @duration_buckets = (
	1,
	5,
	10,
	15,
	30,
	45,
	60,
	90,
	120,
	240,
	360,
	480,
	600,
	1800,
	3600,
	7200,
	14400,
	43200,
	86400,
	172800,
	259200,
	345600,
	432000,
	518400,
	604800,
);

my @size_hist = (0)x@size_buckets;
my @duration_hist = (0)x@duration_buckets;

my $total_size = 0;
my $total_count = 0;
my $total_duration = 0;

#my $json = JSON::XS->new();

# skip the first line
#warn "Skipping the first line ...";
#my $header = <>;

my $rows = ();

# read in every flow record, one per line
while ( my $line = <> ) {
    #warn $line;

    #my ( $start, $end, $duration, $src_ip, $dst_ip, $src_port, $dst_port, $proto, $flg, $fwd, $stos, $input_packets, $input_bytes, $output_packets, $output_bytes ) = split( /,/, $line );
    my ( $ts,$te,$td,$sa,$da,$sp,$dp,$pr,$flg,$fwd,$stos,$ipkt,$ibyt,$opkt,$obyt,$in,$out,$sas,$das,$smk,$dmk,$dtos,$dir,$nh,$nhb,$svln,$dvln,$ismc,$odmc,$idmc,$osmc,$mpls1,$mpls2,$mpls3,$mpls4,$mpls5,$mpls6,$mpls7,$mpls8,$mpls9,$mpls10,$ra,$eng,$bps,$pps,$bpp ) = split( /\s*,\s*/, $line);
    my $start = str2time( $ts ); #. " " . $tst );
    my $end   = str2time( $te ); # . " " . $tet );

    if ( !defined $start || !defined $end ) {
        die "Invalid line!: $!";
        next;
    }

	#my $duration = $flowlength;

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
    #$row->{'start'} = str2time( $ts );
    #$row->{'end'} = str2time( $te );
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

    push @$rows, $row;
    #print encode_json $row;

    #my $sum_bytes = $bytes;
    $total_size += $sum_bytes;
    $total_duration += $td;
    $total_count++;

    my $i = 0;
    foreach my $bucket (@size_buckets ) {
	if ( $sum_bytes <= $bucket ) {
		$size_hist[$i]++;
		last;
		#next LINE;
	}

	$i++;		
    }
	# if we reached this point, we're at greater than the max bucket available. 
	#warn "got a value greater than the highest bucket";

	$i = 0;
    foreach my $bucket (@duration_buckets ) {
	if ( $td <= $bucket ) {
		$duration_hist[$i]++;
		last;
		#next LINE;
	}

	$i++;		
    }
	# if we reached this point, we're at greater than the max bucket available. 
	#warn "got a value greater than the highest bucket";

}

print encode_json $rows;


if ( 0 ) {

#print Dumper \@size_hist;

    print "Size hist CSV: \n";
#print Dumper \@size_hist;

    for (my $i=0;$i<@size_hist;$i++) {
        print $size_buckets[$i] . "," . $size_hist[$i] . "\n";
    }

    print "Size hist: \n";
    for (my $i=0;$i<@size_hist;$i++) {
        my $bytes =  10**($i+3);
        my $size = format_bytes( $bytes );
        print "$size_hist[$i]\t";
        print " <= $size ( $bytes bytes )\n";

    }

    print "Duration hist CSV:\n";
    for (my $i=0;$i<@duration_hist;$i++) {
        print $duration_buckets[$i] . "," . $duration_hist[$i] . "\n";
    }


#print Dumper \@duration_hist;

    for (my $i=0;$i<@duration_hist;$i++) {
        my $duration = $duration_buckets[$i];
        $duration = duration($duration);
        my $hist = $duration_hist[$i];
        print "$hist\t";
        print " <= $duration\n";

    }

    print "\nSummary:\n";
    print "Total size: $total_size (" . format_bytes($total_size, bs => 1000)  . ")\n";
    print "Total count: $total_count\n";
    print "Total duration: $total_duration (" . duration($total_duration) . ")\n";

}
