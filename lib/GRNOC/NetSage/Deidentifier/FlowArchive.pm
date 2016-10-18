package GRNOC::NetSage::Deidentifier::FlowArchive;

use strict;
use warnings;

use Moo;

extends 'GRNOC::NetSage::Deidentifier::Pipeline';

use GRNOC::Log;
use GRNOC::Config;

use JSON::XS;
use Number::Bytes::Human qw(format_bytes);
use Time::Duration;
use Time::HiRes qw( time );
use Try::Tiny;

use Data::Dumper;

### internal attributes ###

has handler => ( is => 'rwp');

has json => ( is => 'rwp' );

has archive_path => ( is => 'rwp' );

has archive_file => ( is => 'rwp', default => "flow_archive.jsonl" );

### constructor builder ###

sub BUILD {

    my ( $self ) = @_;

    my $config_obj = $self->config;
    my $config = $config_obj->get('/config');
    $self->_set_archive_path( $config->{'archive_path'} );
    my $file = $config->{'archive_file'};
    if ( defined $file ) {
        $self->_set_archive_file( $file );

    }
    my $json = JSON::XS->new();
    $self->_set_json( $json );

    $self->_set_handler( sub { $self->_archive_flows(@_) } );

    return $self;
}

### private methods ###

sub _archive_flows {
    my ( $self, $caller, $input_data ) = @_;
    my $path = $self->archive_path;

    warn "number of flows: " . @$input_data;
    #warn "path = $path";

    #my $ts = time(); # this needs to be a float 
    #my $filename = $ts . ".json";
    my $filename = $self->archive_file;

    my $filepath = $path . "/" . $filename;
    #if ( -e $filepath ) {
    #    die "FILE EXISTS: $filepath";
    #}
    open my $fh, '>>', $filepath;
    print $fh $self->json->encode( $input_data ) . "\n";
    close $fh;


    #return; # basically dying
    #foreach my $row (@$input_data) {
    #    my $five_tuple = $row->{'meta'}->{'src_ip'};
    #    $five_tuple .= $row->{'meta'}->{'src_port'};
    #    $five_tuple .= $row->{'meta'}->{'dst_ip'};
    #    $five_tuple .= $row->{'meta'}->{'dst_port'};
    #    $five_tuple .= $row->{'meta'}->{'protocol'};
    #    #warn "five_tuple: $five_tuple\n";

    #    my $start = $row->{'start'};
    #    my $end = $row->{'end'};
    #    my $duration = $end - $start;

    #}


    #return $finished_messages;
    # Return just a dummy array so it knows we were successful
    return [ 'finished' ];
}

1;
