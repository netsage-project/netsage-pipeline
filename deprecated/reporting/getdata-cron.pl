#!/usr/bin/perl

use warnings;
use strict;

use Date::Format;
use File::Path;
use Proc::ProcessTable;
use JSON::XS;

use Data::Dumper;

my $command = "/home/mj82/rabbitmqadmin list queues -d 2 -f raw_json";

my $filetemplate = "%H-%M-%S";
my $timestamp = time;
my $timestring = time2str( $filetemplate, $timestamp );
my $dir = "/home/mj82/data/rabbitstats";

my $template = "/%Y/%m/%d";
my $date_path = time2str( $template, $timestamp );

$dir .= $date_path;

if ( ! -d $dir ) {
	mkpath($dir) or die "Error creating directory: $dir; $?";
} 
my $outfile = $dir . "/pipeline_stats_$timestring.json";
my @patterns = (
	"^netsage_",
	"rabbitmq_server"

);

my $json = JSON::XS->new();

# get process info
my $t = new Proc::ProcessTable;
my @fields = $t->fields;
@fields = sort { lc($a) cmp lc($b) } @fields;

my $processes = [];

foreach my $p ( @{$t->table} ) {
	my $cmd = $p->{'cmndline'};
	my $found = 0;
	my $process = {};
	foreach my $pattern ( @patterns ) {
		if ( $cmd =~ /$pattern/ ) {
			$found++;
		}

	}
	next if $found == 0;
	
	foreach my $field ( @fields ) {
		$process->{ $field } = $p->{ $field };

	}
	push @$processes, $process;

}

my $filename = $dir . "/rabbit_stats_$timestring.json";

#$command = $command . " > " . $filename;

my $rabbit_status_raw = `$command`
	or die "system $command failed: $?";

my $rabbit_status = $json->decode( $rabbit_status_raw ) or warn "Unable to decode message: $_";

my $out = {};

$out->{'timestamp'} = $timestamp;
$out->{'rabbit_status'} = $rabbit_status;
$out->{'processes'} = $processes;

open ( my $fh, '>', $outfile ) or die "Error writing file: $_!";
print $fh $json->encode( $out );
close $fh;

#system($command) == 0
#	or die "system $command failed: $?";


