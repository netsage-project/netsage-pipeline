package GRNOC::NetSage::Deidentifier::DataService::ScienceRegistry;

use strict;
use warnings;

use Moo;

use GRNOC::Log;
use GRNOC::Config;

use JSON::XS;
use Math::Round qw( nlowmult nhimult );
use List::MoreUtils qw( natatime );
use Try::Tiny;
use Data::Validate::IP;
use Net::IP;
use Hash::Merge qw( merge );
use POSIX;
use Net::CIDR::Lite;

use Data::Dumper;

### constants ###

use constant RECONNECT_TIMEOUT => 10;

### required attributes ###

has config => ( is => 'ro',
                required => 1 );

has logger => ( is => 'rwp', 
                required => 1);


#has logging_file => ( is => 'ro',
#                      required => 1 );

#has process_name => ( is => 'ro',
#                      required => 1 );

# input queue, identified by name
#has input_queue_name => ( is => 'ro',
#                     required => 1 );

# output queue, identified by name
#has output_queue_name => ( is => 'ro',
#                     required => 1 );

#has handler => ( is => 'rwp');
#                 required => 1 );

### internal attributes ###

has json => ( is => 'rwp' );

has data_file => ( is => 'rwp' );

has scireg => ( is => 'rwp' );

### constructor builder ###

sub BUILD {

    my ( $self ) = @_;

    # create and store logger object
    #my $grnoc_log = GRNOC::Log->new( config => $self->logging_file );
    #my $logger = GRNOC::Log->get_logger();
    #
    #$self->_set_logger( $logger );

    # create and store config object
    #my $config_obj = GRNOC::Config->new( config_file => $self->config_file,
    #                                 force_array => 0 );


    # create and store shared config object
    #my $shared_config_obj;
    #my $shared_config = {};
    #if ( defined ( $self->shared_config_file ) ) {
    #    $shared_config_obj = GRNOC::Config->new( config_file => $self->shared_config_file,
    #        force_array => 0 );
    #    my $new_shared_config = {};
    #    if ( !$shared_config_obj->{'error'} ) {
    #        $new_shared_config = $shared_config_obj->get('/*');
    #        if ( $new_shared_config ) {
    #            $shared_config = $new_shared_config;
    #        }
    #    }
    #}

    #my $config_single = $config_obj->get('/*') or die "DEATH2!!";

    # Merge the hashes; the "single" values should overrride those
    # from the "shared" config.
    #my $config = merge( $config_single, $shared_config );

    #$self->_set_config( $config );

    my $json = JSON::XS->new();
    $self->_set_json( $json );

    warn "Science Registry Config\n" . Dumper $self->config;

    my $data_file = $self->config->{'scireg'}->{'location'};
    $self->_set_data_file( $data_file );

    $self->_init_datasource();

    #my $address = "131.217.63.225"; #UTAS  # TODO: make this dynamic
    #$self->get_metadata( $address );

    return $self;
}


### private methods ###

sub _init_datasource {
    my ( $self ) = @_;
    my $file = $self->data_file;

    warn "data file: $file";

    # import the JSON file

    my $json = $self->json;
    my $rabbit_batch_size = 100;
    open my $fh, '<:encoding(UTF-8)', $file;
    # we assume each line is 1 Rabbit message 
    # (which typically may contain up to 100 flows)
    my $batch = [];
    my $push_now;
    my $content = "";
    {
        local $/ = undef;
        open FILE, $file or die "Couldn't open data file: $!";
        binmode FILE;
        $content = <FILE>;
        close FILE;
    }
    #warn "content: " . $content;

    my $data = $json->decode( $content );
    $self->_set_scireg( $data );
    #warn "data from json\n" . Dumper $data;
    warn "number of records: " . @$data;


}

### public methods ###

sub get_metadata {
    my ( $self, $address ) = @_;
    my $scireg = $self->scireg;
    # TODO: method for searching metadata is inefficient, improve when time
    foreach my $row (@$scireg ) {
        my $addresses = $row->{'addresses'};
        #warn "addresses : " . Dumper $addresses;
        foreach my $addr ( @$addresses ) {
            my $cidr = Net::CIDR::Lite->new;
            $addr =~ s/^\s+|\s+$//g;
            my $success = 0;
            try {
                $cidr->add_any( $addr );
                #warn "cidrs " . Dumper $cidr->list();
                if ( $cidr->find( $address ) ) {
                    warn "!!!!!!!!!!!!address found in cidr range!\n" . Dumper $row;
                    $success = 1;
                    #return $row;
                } else {
                    #warn "address not found $address in " . Dumper $row;
                    $success = 0;
                }

            } catch {
                warn "WARNING: Error adding address: " . $addr;
                $success = 0;
                #return;
            };
            if ( $success ) {
                return $row;
            }

        }

    }


}

1;
