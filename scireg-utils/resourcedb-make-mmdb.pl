#!/usr/bin/env perl
#
# NOTE: this script is obsolete! It uses the old style scireg.mmdb
#  leaving the code here as an archive

# This script reads a json export of the Science Registry database and
# converts it into a fake GeoIP database (.mmdb file) that can be used by the logstash GeoIP filter to do science registry tagging.
# The Science Registry info is stored (as json) in the city name field.  Logstash can use the json filter to break it up.
# Each db entry is for an individual cidr address. They are sorted so the longest prefixes (most specific addresses) come last, since
# the logstash GEOIP FILTER gets the LAST MATCH for an IP address.
# If successful, this script writes a timestamp to status.txt in /var/lib/scienceregistry-mmdb-file/status.txt.
# RUNS VIA CRON

# see https://blog.maxmind.com/2015/09/29/building-your-own-mmdb-database-for-fun-and-profit/
# also https://stackoverflow.com/questions/47655730/maxmind-writer-to-create-custom-database-to-use-with-geoip-in-elk-stack
# and https://metacpan.org/pod/MaxMind::DB::Writer::Tree#DATA-TYPES

use strict;
use warnings;
use Data::Dumper;

use Getopt::Long;
use JSON::XS;
use Net::IP;
use MaxMind::DB::Writer::Tree;
#use GRNOC::Monitoring::Service::Status;

# command line params are input and output file names
my $scireg_json_file = '/usr/share/resourcedb/www/exported/scireg.json';
my $outfile = '/usr/share/resourcedb/www/exported/scireg.mmdb';
my $help;
GetOptions(
    "input|i=s" => \$scireg_json_file,
    "output|o=s" => \$outfile,
    "help|?"  =>  \$help
);
if ($help) {
    print "USAGE: perl make_mmdb.pl [-i <scireg.json file> -o <scireg.mmdb file>] \n";
    exit;
}
if (! -e $scireg_json_file) {
    warn "ERROR: json file $scireg_json_file does not exist";
    exit;
}
my $fh_out;
if (! open $fh_out, '>:raw', $outfile) {
    warn "ERROR: Could not open $outfile";
    exit;
}
close($fh_out);

# The MMDB format is strongly typed but perl is not, so we need to specify types.
# (a "map" is a hash. list types of keys within the maps just once)
# * The logstash filter ignores all except fields with a usual geoip db name and type!
my %types = (
 city => 'map',
 location => 'map',
 names => 'map',
 en => 'utf8_string',
 latitude => 'double',
 longitude => 'double',
);

# DB::Writer::Tree -
# params are required unless I say [optional]!
#-"database_type"
# * The geoip logstash filter requires this to be one of the maxmind databases-'GeoIP2-City', 'GeoIP2-Country', etc!
#-"description"
# * The geio ip logstash filter requires this to be the description of the real geoip db
#-"ip_version" can be either 4 or 6 (use 6 so ipv6's can fit (tree depth = 128 bits))
#-"record_size" is the record size in bits.  Either 24, 28 or 32. Depends on no. of nodes in the db.
#    based on number of nodes in the search tree + 16 (data section separator) + the sum of the length of all unique data items, or something like that. ???
#-"languages" [optional] - don't have to list them here (at least if just en[glish]), still have to use en=> in assignments
#-"merge_strategy=>none" = no copying or overwriting data from one address/record to another, even if one is a subset of the other.
#-"map_key_type_callback" - callback to validate data going into the database (see %types above)
# THIS CAN HOLD BOTH IPV4 AND IPV6 CIDRS
my $tree = MaxMind::DB::Writer::Tree->new(
    database_type => 'GeoIP2-City',
    description => { en => 'Fake GeioIP2-City db for Science Registry' },
    ip_version => 6,
    record_size => 28,
    languages   => ['en'],
    merge_strategy => 'none',
    map_key_type_callback => sub { $types{ $_[0] } },
);

# read science registry json file
open(my $fh_in, '<', $scireg_json_file) or die "Could not open $scireg_json_file";
read($fh_in, my $scireg_json, -s $fh_in);
close($fh_in);

# convert json file to hashes with keys= single CIDRs and values= resource info  (separating ipv4 and ipv6 addresses)
my $scireg = decode_json $scireg_json;
my %ipv4_singles;
my %ipv6_singles;
foreach my $res (@$scireg) {
    # Make a copy of the hash, remove the addresses array and string for anonymization purposes, get lat and long.
    my %data = %$res;
    #delete $data{'addresses_str'};
    #delete $data{'addresses'};
    #delete $data{'ip_block_id'};
    my $lat = $data{'latitude'};
    my $long = $data{'longitude'};
    # convert back to json
    my $data_json = encode_json \%data;

    # For each cidr block/address in this resource, save the json in the "city name" geoip field
    # (another logstash filter will break it up later)
    # Latitude and longtude are required in order for the logstash geoip filter to return a match!
    foreach my $addr (@{$res->{'addresses'}}) {
        if ( $addr =~ /:/) {
            $ipv6_singles{$addr} = {
                            'city' => { 'names' => { 'en' => $data_json } },
                            'location' => { 'latitude' => $lat, 'longitude' => $long }
                             };
        } else {
            $ipv4_singles{$addr} = {
                            'city' => { 'names' => { 'en' => $data_json } },
                            'location' => { 'latitude' => $lat, 'longitude' => $long }
                             };
        }
        print "added $addr \n";
    }
}

# Add singles to the fake geoip db IN THE RIGHT ORDER, with most precise/longest prefix addresses last
# (This is required since the logstash geoip filter will return the LAST match)
for my $address ( sort byprefix  keys %ipv4_singles ) {
    $tree->insert_network( $address, $ipv4_singles{$address} );
    print "added $address \n";
}
print "----------\n";
for my $address ( sort byprefix  keys %ipv6_singles ) {
    $tree->insert_network( $address, $ipv6_singles{$address} );
    print "added $address \n";
}
print "----------\n";

# Write the databases to disk.
open ($fh_out, '>:raw', $outfile);
$tree->write_tree( $fh_out );
close $fh_out;

# Check the file size
if ( -s $outfile > 3000 ) {
    print "$outfile has been created\n";
    # on success, write status file for monitoring
    # only work at GRNOC
    #write_status("");
} else {
    warn "$outfile seems to be too small. Check to be sure it is ok.";
}

#------------
sub byprefix {
    # This a sort function for IP's in CIDR notation.
    # Sort first by prefix (the /xx).
    # If /xx's of $a and $b are the same, convert to Net::IP objects and compare the IP parts as integers.
    # (Use Net::IP and intip method so this works for both ipv4 and ipv6)
    my $result = ($a =~ /\/(\d+)$/)[0] <=> ($b =~ /\/(\d+)$/)[0];
### need to worry about this sorting??
    if ($result == 0) {
        my $aa = Net::IP->new($a);
        my $bb = Net::IP->new($b);
        # ran into this sitation at least once. This will make the problem IP come out as the last /xx.
        if(!$aa) { warn "$a - warning: couldn't make a Net::IP object!?\n"; warn(Net::IP::Error()); return -1; }
        if(!$bb) { warn "$b - warning: couldn't make a Net::IP object!?\n"; warn(Net::IP::Error()); return -1; }
        return ($aa->intip) <=> ($bb->intip);
    } else {
        return $result;
    }
}

sub write_status {
    # writes to /var/lib/scienceregistry-mmdb-file/status.txt
    my $error_text = shift;
    my $error = 0;
    if ($error_text) { $error=1; }


    my $result = write_service_status( path => "/var/lib/scienceregistry-mmdb-file/",
                                       error => $error,
                                       error_txt => $error_text,
                                       timestamp => time() );
    if ( !$result) {
        warn("Problem writing scienceregistry-mmdb-file status.txt file. Be sure you are running as root.");
        exit 1;
    }
}
