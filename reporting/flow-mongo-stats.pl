#!/usr/bin/perl

use strict;
use warnings;

use GRNOC::Config;
use MongoDB;

use Data::Dumper;
use MIME::Lite;
use Getopt::Long;

my $USAGE = "$0 --to <email>";

my $email_to = "";

GetOptions("to=s" => \$email_to) or die $USAGE;

if (! $email_to){
    die $USAGE;
}

my $config = GRNOC::Config->new(config_file => "/etc/grnoc/tsds/services/config.xml",
				force_array => 0);

my $host = $config->get('/config/mongo/@host');
my $port = $config->get('/config/mongo/@port');
my $user = $config->get('/config/mongo/root');

my $mongo = MongoDB::MongoClient->new(
    host     => "$host:$port",
    username => $user->{'user'},
    password => $user->{'password'}
    );

my $flow_db = $mongo->get_database('flow');

my $measurements_count = $flow_db->get_collection('measurements')->count();
my $data_count = $flow_db->get_collection('data')->count();
my $storage_stats = $flow_db->run_command( { dbStats => 1 } );

my $string = "Information for 'flow' database:\n\n";
$string .= "Num Measurement Docs -> $measurements_count\n";
$string .= "Num Data Docs        -> $data_count\n";
$string .= "Sizeof Data bytes    -> $storage_stats->{'dataSize'}\n";
$string .= "Sizeof Storage bytes -> $storage_stats->{'storageSize'}\n";

my $msg = MIME::Lite->new(
    From     => 'flow-usage-report@netsage-archive',
    To       => $email_to,       
    Subject  => 'Flow DB Usage Report for ' . localtime(time()),
    Type     => 'text/plain',
    Data     => $string
    );

$msg->send;
