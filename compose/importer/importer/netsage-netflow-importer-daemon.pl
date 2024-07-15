#!/usr/bin/perl

use strict;
use warnings;
#use diagnostics;

use lib '.';

use NetSage::NetflowImporter;
use NetSage::WorkerManager;

use Getopt::Long;
use Data::Dumper;

### constants ###
use constant DEFAULT_CONFIG_FILE => '/tmp/conf/netsage_netflow_importer.xml';
use constant DEFAULT_SHARED_CONFIG_FILE => '/tmp/conf/netsage_shared.xml';
#use constant DEFAULT_LOGGING_FILE => '/tmp/conf/logging.conf';
# for more debugging
use constant DEFAULT_LOGGING_FILE => '/tmp/conf/logging-debug.conf';

### command line options ###

my $config = DEFAULT_CONFIG_FILE;
my $logging = DEFAULT_LOGGING_FILE;
my $shared_config = DEFAULT_SHARED_CONFIG_FILE;
my $nofork;
my $flowpath;
my $cachefile;
my $help;

GetOptions( 'config=s' => \$config,
            'sharedconfig=s' => \$shared_config,
            'logging=s' => \$logging,
            'nofork' => \$nofork,
            'flowpath=s' => \$flowpath,
            'cachefile=s' => \$cachefile,
            'help|h|?' => \$help );

# did they ask for help?
usage() if $help;

# start/daemonize importer 
my $flow_importer = NetSage::NetflowImporter->new( config_file => $config,
                                                          shared_config_file => $shared_config,
                                                          logging_file => $logging,
                                                          daemonize => !$nofork,
                                                          cache_file => $cachefile,
                                                          process_name => 'netsage_netflow_importer',
                                                          flow_path => $flowpath );

my $worker = NetSage::WorkerManager->new( config_file => $config,
                                                          logging_file => $logging,
                                                          daemonize => !$nofork,
                                                          process_name => 'netsage_netflow_importer',
                                                          worker => $flow_importer );


$worker->start("no_input_queue");
print ("  ** Check ps or /var/log/messages to be sure the processes have started successfully. **\n");

### helpers ###

sub usage {

    print "Usage: $0 [--config <file path>] [--sharedconfig <file path>] [--logging <file path>] [--flowpath <file path>]\n";

    exit( 1 );
}
