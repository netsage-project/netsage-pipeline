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

has sensors => ( is => 'rwp', default => sub { {} } );

### constructor builder ###

sub BUILD {

    my ( $self ) = @_;

    my $config = $self->config;
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

    my $filename = $self->archive_file;

    my %sensors = %{ $self->sensors };

    #warn "input data ref: " . ref $input_data;
    foreach my $row ( @$input_data ) {
        #warn "archive keys: " . Dumper keys %$row;
        my $sensor = $row->{'meta'}->{'sensor_id'};
        #warn "sensor: $sensor";
        if ( ! $sensors{ $sensor } ) {
            $sensors{ $sensor } = 1;
        } else {
            $sensors{ $sensor } += 1;

        }

    }
    $self->logger->debug( "sensor stats " . Dumper \%sensors );
    warn "sensor stats " . Dumper \%sensors;

    $self->_set_sensors( \%sensors );

    my $filepath = $path . "/" . $filename;
    open my $fh, '>>', $filepath;
    print $fh $self->json->encode( $input_data ) . "\n";
    close $fh;

    # Return just a dummy array so it knows we were successful
    return [ 'finished' ];
}

1;
