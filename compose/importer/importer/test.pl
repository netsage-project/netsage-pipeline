#!/usr/bin/perl

use strict;
use warnings;

# Add the path to @INC
#use lib 'NetSage';
#use lib '/home/tierney/src/netsage-pipeline/importer/NetSage';
use lib '.';

# Attempt to load the module
use NetSage::NetflowImporter;
use NetSage::WorkerManager;
use NetSage::myConfig;
use NetSage::Log;

# Print @INC for debugging
print "INC Path:\n";
print "$_\n" for @INC;

# Rest of your code
