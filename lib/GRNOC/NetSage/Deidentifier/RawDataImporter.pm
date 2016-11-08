package GRNOC::NetSage::Deidentifier::RawDataImporter;

use strict;
use warnings;

use Moo;

extends 'GRNOC::NetSage::Deidentifier::Pipeline';

use GRNOC::Log;
use GRNOC::Config;

use JSON::XS;
use List::MoreUtils qw( natatime );
use Number::Bytes::Human qw(format_bytes);
use Time::Duration;
use Time::HiRes qw( time );
use Try::Tiny;

use Data::Dumper;

### internal attributes ###

has handler => ( is => 'rwp');

has json => ( is => 'rwp' );

has json_data => ( is => 'rwp' );

has files => ( is => 'rwp' );

### constructor builder ###

sub BUILD {

    my ( $self ) = @_;

    my $config_obj = $self->config;
    my $config = $config_obj->get('/config');
    #$self->_set_archive_path( $config->{'archive_path'} );
    #my $file = $config->{'archive_file'};
    #if ( defined $file ) {
    #    $self->_set_archive_file( $file );
    #
    #}
    my $json = JSON::XS->new();
    $self->_set_json( $json );

    $self->_set_handler( sub { $self->_import_raw_data(@_) } );

    return $self;
}

### private methods ###

sub _import_raw_data {
    my ( $self, $caller, $input_data ) = @_;
    my $batch_size = 8096;

    my $files = $self->files;
    foreach my $filename (@$files ) {
        if ( $filename =~ /jsonl/ ) {
            # we're dealing with a jsonl file
            $self->_handle_jsonl_file( $filename );

        } else {
            die "Error loading file; must be a .jsonl file";
            # We will extend this to assume our file is a json file. In this case the entire JSON
            # file has to fit in memory at once. We can improve on this later.
        }

    }

    return;
}

sub _handle_jsonl_file {
    my ( $self, $filepath ) = @_;
    my $json = $self->json;
    my $rabbit_batch_size = 100;
    open my $fh, '<:encoding(UTF-8)', $filepath;
    # we assume each line is 1 Rabbit message 
    # (which typically may contain up to 100 flows)
    my $batch = [];
    my $push_now;
    while ( my $line = <$fh> ) {
        $push_now = 0;
        chomp $line;
        my $decoded = $json->decode( $line ) or do {
            $self->logger->warn( "SKIPPING LINE - Error decoding json: $!" );
            next;
        };
        if ( ref( $decoded ) eq "HASH" ) {
            push @$batch, $decoded;

        } elsif ( ref ( $decoded ) eq "ARRAY" ) {
            $batch = $decoded;
            $push_now = 1;

        }

        if ( @$batch >= $rabbit_batch_size || $push_now  ) {
            $batch = _process_data( $batch );
            $self->_set_json_data( $batch );
            $self->_publish_messages();
            $batch = [];
            $push_now = 0;
        }

    }
    if ( @$batch > 0 ) {
        $batch = _process_data( $batch );
        $self->_set_json_data( $batch );
        $self->_publish_messages();
        $batch = [];
        $push_now = 0;

    }
    close $fh;
    $self->_set_is_running( 0 );
}

sub _process_data {
    my $data = shift;

    foreach my $row ( @$data ) {
        $row = _cleanup_null_values( $row );
    }
    return $data;
}

# clean up null values
# metadata only accepts strings or ""
# values only accepts numeric or null
# set null to '' 
sub _cleanup_null_values {
    my $obj = shift;
    $obj->{'meta'} = _null_to_empty_string( $obj->{'meta'} );
    $obj->{'values'} = _empty_string_to_null( $obj->{'values'} );

        #foreach my $key ( keys %$obj ) {
        #my $val = $obj->{$key};
        #$val->{'meta'} = _null_to_empty_string( $val->{'meta'} );
        #$val->{'values'} = _empty_string_to_null( $val->{'values'} );
        #}
        #warn "after checking defined value: " . Dumper $obj;
        #die;

    return $obj;
}

sub _null_to_empty_string {
    my $obj = shift;
    foreach my $key ( keys %$obj ) {
        my $val = $obj->{$key};
        $val = "" if not defined $val;
        $obj->{$key} = $val;
    }
    return $obj;
}

sub _empty_string_to_null {
    my $obj = shift;
    foreach my $key ( keys %$obj ) {
        my $val = $obj->{$key};
        undef $val if ( ( defined $val ) && ( $val eq "" ) );
        $obj->{$key} = $val;
    }
    return $obj;
}

sub _publish_messages {
    my $self = shift;
    my $messages = $self->json_data;
    if ( $messages > 0 ) {
        $self->_publish_data( $messages );
    }
    $self->_set_json_data( [] );
}


1;
