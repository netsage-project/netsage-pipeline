#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
#
# This script is used to process as-org database files downloaded from caida.org
# into the format the netsage pipeline requires.
#
# First, get the txt file from caida (these are released quarterly)
# eg, $ wget https://publicdata.caida.org/datasets/as-organizations/20210401.as-org2info.txt.gz
# and $ gunzip 20210401.as-org2info.txt.gz
#
# Then run this script
# eg, $ process-caida-file.pl 20210401.as-org2info.txt
#     CAIDA-test.csv will be created.
#
# Save the final file with a name like CAIDA-2021-0401-lookup.csv
# Do a test run to be sure things are ok, as much as possible.
#
# Finally,
# Copy it to scienceregistry.grnoc.iu.edu - /usr/share/resourcedb/www/exported/CAIDA-org-lookup.csv
# so cron jobs on pipeline hosts will start downloading it.
# Note that it won't be used in the pipeline until logstash restarts. IU hosts have a cron job to restart logstash.
# (Docker instances will download it periodically but they don't currently restart logstash automatically.)
#
my $input_file = $ARGV[0];
if (! -e $input_file) { die ("$input_file was not found\n"); }
if (! open( INFILE, '<', $input_file) ) { die ("Error opening $input_file\n"); };
print ("Processing $input_file\n");

my $output_file = "caida-test.csv";
if (! open( OUTFILE, '>', $output_file) ) { die ("Error opening $output_file\n"); };
print ("Writing $output_file\n");

my $orgs;
my $asn_orgs;
my $section = "headers";
while (my $line = <INFILE> ) {
    chomp $line;
    next if ($section eq "headers" and $line !~ /format:/);
    if ($section eq "headers" and $line =~ /format:/) {
        $section = "orgs";
        next;
    }
    if ($section eq "orgs" and $line =~ /format:/) {
        $section = "asns";
        next;
    }

    # have to escape the | separator!
    my @parts = split('\|', $line);

    if ($section eq "orgs") {
        # $orgs with key org-id = org-name
        $orgs->{$parts[0]} = $parts[2];
    }

    if ($section eq "asns") {
        # $asn_orgs with key asn = org-name
        $asn_orgs->{$parts[0]} = $orgs->{$parts[3]};
    }
}

# sort by ASN
my @sorted_asns = sort {$a <=> $b} keys $asn_orgs;

foreach my $asn (@sorted_asns) {
    my $org = $asn_orgs->{$asn};
    # handle missing orgs, quotes, backslashes, and commas in org names
    if (! $org) { $org = "Unknown"; }
    $org =~ s/\\/ /g;
    $org =~ s/"/""/g;
#    if ($org =~ /[,"]/) { $org = '"'.$org.'"'; }
    $org = '"'.$org.'"';

    # asn's are keys in the translate filter and they definitely need to be strings in quotes
    $asn = '"'.$asn.'"';

    print (OUTFILE  $asn.','.$org."\n");
}
