#!/usr/bin/perl

use Data::Dumper;
use strict;
use warnings;
use JSON::XS;
use Try::Tiny;

binmode STDOUT, ":utf8";
use utf8;
 

my $json = JSON::XS->new();

my $file = 'data/data1.json';
my $json_data;
{
    local $/; #Enable 'slurp' mode
    open my $fh, "<", $file;
    $json_data = <$fh>;
    close $fh;
}

my $data;
try {
    $data = $json->decode( $json_data );

}

catch {

    warn( "Unable to JSON decode message: $_" );
};


warn "data: ";
warn Dumper $data;

