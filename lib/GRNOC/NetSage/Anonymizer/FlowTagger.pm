package GRNOC::NetSage::Anonymizer::FlowTagger;

use strict;
use warnings;

use Moo;
use Socket;
use Socket6;
use Geo::IP;
use Data::Validate::IP;
use Net::IP;

use GRNOC::NetSage::Anonymizer::Pipeline;
use GRNOC::Log;
use GRNOC::Config;

use Data::Dumper;


### required attributes ###

has config_file => ( is => 'ro',
                required => 1 );

has logging_file => ( is => 'ro',
                      required => 1 );

### internal attributes ###
            
has logger => ( is => 'rwp' );

has config => ( is => 'rwp' );

has pipeline => ( is => 'rwp' );

has handler => ( is => 'rwp');

has geoip_country => ( is => 'rwp' );
has geoip_country_ipv6 => ( is => 'rwp' );

has geoip_city => ( is => 'rwp' );
has geoip_city_ipv6 => ( is => 'rwp' );

has geoip_asn => ( is => 'rwp' );
has geoip_asn_ipv6 => ( is => 'rwp' );

### constructor builder ###

sub BUILD {

    my ( $self ) = @_;

    # create and store logger object
    my $grnoc_log = GRNOC::Log->new( config => $self->logging_file );
    my $logger = GRNOC::Log->get_logger();

    $self->_set_logger( $logger );

    # create and store config object
    my $config = GRNOC::Config->new( config_file => $self->config_file,
                                     force_array => 0 );

    $self->_set_config( $config );


    # create the Pipeline object, which handles the Rabbit queues

    my $pipeline = GRNOC::NetSage::Anonymizer::Pipeline->new(
        config_file => $self->config_file,
        logging_file => $self->logging_file,
        input_queue_name => 'raw',
        output_queue_name => 'tagged',
        handler => sub { $self->_tag_messages(@_) },
        process_name => 'netsage_flowtagger',
    );
    $self->_set_pipeline( $pipeline );
    warn "config: " . Dumper $config->get('/config');

    # TODO : extend this to ipv6
    # TODO: review whether we need the country db. the city db seems to have 
    # all the country data as well
    #my $geoip_country_file = $config->get( '/config/geoip/config_files/country' );
    #my $geoip_country = Geo::IP->open( $geoip_country_file, GEOIP_MEMORY_CACHE);
    #warn "geoip_country_file: $geoip_country_file";
    #$self->_set_geoip_country( $geoip_country );

    my $geoip_country_ipv6_file = $config->get( '/config/geoip/config_files/country_ipv6' );
    my $geoip_country_ipv6 = Geo::IP->open( $geoip_country_ipv6_file, GEOIP_MEMORY_CACHE);
    warn "geoip_country_ipv6_file: $geoip_country_ipv6_file";
    $self->_set_geoip_country_ipv6( $geoip_country_ipv6 );

    my $geoip_asn_file = $config->get( '/config/geoip/config_files/asn' );
    my $geoip_asn = Geo::IP->open( $geoip_asn_file, GEOIP_MEMORY_CACHE);
    warn "geoip_asn_file: $geoip_asn_file";
    $self->_set_geoip_asn( $geoip_asn );

    my $geoip_asn_ipv6_file = $config->get( '/config/geoip/config_files/asn_ipv6' );
    my $geoip_asn_ipv6 = Geo::IP->open( $geoip_asn_ipv6_file, GEOIP_MEMORY_CACHE);
    warn "geoip_asn_ipv6_file: $geoip_asn_ipv6_file";
    $self->_set_geoip_asn_ipv6( $geoip_asn_ipv6 );

    my $geoip_city_ipv6_file = $config->get( '/config/geoip/config_files/city_ipv6' );
    my $geoip_city_ipv6 = Geo::IP->open( $geoip_city_ipv6_file, GEOIP_MEMORY_CACHE);
    warn "geoip_city_ipv6_file: $geoip_city_ipv6_file";
    $self->_set_geoip_city_ipv6( $geoip_city_ipv6 );
    #die "Please install the CAPI for IPv6 support\n" unless Geo::IP->api eq 'CAPI';


    my $geoip_city_file = $config->get( '/config/geoip/config_files/city' );
    my $geoip_city = Geo::IP->open( $geoip_city_file, GEOIP_MEMORY_CACHE);
    warn "geoip_city_file: $geoip_city_file";
    $self->_set_geoip_city( $geoip_city );

    return $self;
}

### public methods ###

sub start {

    my ( $self ) = @_;
    return $self->pipeline->start();

}

### private methods ###

# expects an array of data for it to tag
# returns the tagged array
sub _tag_messages {
    # TODO: the actual tagging
    my ( $self, $caller, $messages ) = @_;
    #my $geoip_country = $self->geoip_country;
    my $geoip_city = $self->geoip_city;
    my $geoip_city_ipv6 = $self->geoip_city_ipv6;
    my $geoip_country_ipv6 = $self->geoip_country_ipv6;
    my $geoip_asn = $self->geoip_asn;
    my $geoip_asn_ipv6 = $self->geoip_asn_ipv6;

    my $finished_messages = $messages;

    foreach my $message ( @$messages ) {
        my @fields = ( 'src_ip', 'dst_ip');
        foreach my $field ( @fields ) {
            my $field_direction = $field;
            $field_direction =~ s/_ip//g;
            my $ip = $message->{'meta'}->{ $field };
            my %metadata = ();
            my $asn_org;

            if ( is_ipv4( $ip ) ) {
                #my $record = $geoip->record_by_addr( $ip );
                my $record;
                my ( $country_code, $country_name, $city, $latitude, $longitude );
                #my $country_code = $geoip_country->country_code_by_addr( $ip );
                #my $country_name = $geoip_country->country_name_by_addr( $ip );

                $asn_org = $geoip_asn->org_by_addr( $ip );


                $record = $geoip_city->record_by_addr( $ip );

                if ( $record ) {
                    $metadata{'country_code'} = $record->country_code;
                    $metadata{'country_name'} = $record->country_name;
                    $metadata{'city'} = $record->city;
                    $metadata{'region'} = $record->region;
                    $metadata{'region_name'} = $record->region_name;
                    $metadata{'postal_code'} = $record->postal_code;                
                    $metadata{'time_zone'} = $record->time_zone;
                    $metadata{'latitude'} = $record->latitude;
                    $metadata{'longitude'} = $record->longitude;

                    #warn "metadata: " . Dumper %metadata;

                }
                
                warn "$field: $ip; record:";
                #warn Dumper $record;
                if ( $country_code ) {
                    warn "\ncountry code: $country_code\n";
                    warn "country name: $country_name";
                }
                if ( $asn_org ) {
                    warn "asn_org ipv4: '$asn_org'";

                }
            } elsif ( is_ipv6( $ip ) )  {
                # TODO: extend to ipv6

                my $record;
                $record = $geoip_city_ipv6->record_by_addr_v6( $ip );
                warn "country_name IPV6 " . $geoip_country_ipv6->country_name_by_addr_v6( $ip );
                warn "country_code IPV6 " . $geoip_country_ipv6->country_code_by_addr_v6( $ip );

                $asn_org =  $geoip_asn_ipv6->name_by_addr_v6 ( $ip );
                if ( $asn_org ) {
                    warn "\n\nASN V6: $asn_org\n\n";
                }

                if ( $record ) {
                    # NOTE: some of these don't seem to work for ipv6:
                    # city, region/region_name, postal_code, time_zone
                    $metadata{'country_code'} = $record->country_code;
                    $metadata{'country_name'} = $record->country_name;
                    $metadata{'city'} = $record->city;
                    $metadata{'region'} = $record->region;
                    $metadata{'region_name'} = $record->region_name;
                    $metadata{'postal_code'} = $record->postal_code;                
                    $metadata{'time_zone'} = $record->time_zone;
                    $metadata{'latitude'} = $record->latitude;
                    $metadata{'longitude'} = $record->longitude;

                    #warn "metadata IPV6: " . Dumper \%metadata;

                }




            } else {
                # not detected as ipv4 nor ipv6
                warn "\n\nNOTICE: address not detected as ipv4 or ipv6: $ip\n\n";
                $self->logger->warn( "NOTICE: address not detected as ipv4 or ipv6: $ip"  );
                # TODO: handle failure better

            }
                if ( $asn_org =~ /^AS(\d+)\s+(.+)$/ ) {
                    warn "ASN: $1; ORG: '$2'";
                    my $asn = $1;
                    my $organization = $2;
                    $metadata{'asn'} = $asn;
                    $metadata{'organization'} = $organization;

                } else {
                    warn "\n\nASN/ORG don't match regex\n\n";
                }

            # for now, we're going to tag these:
            # ASN
            # Country Code
            # Country Name
            # Latitude
            # Longitude
            my @meta_names = ( 'asn', 'city', 'country_code', 'country_name', 
                'latitude', 'longitude', 'organization');
            foreach my $name ( @meta_names ) {
                $message->{'values'}->{ $field_direction ."_" . $name } = $metadata{ $name } if $metadata{ $name };
            }

        }


        # $message->{'src_ip'} = $self->_anonymize_ip( $message->{'src_ip'} );
        # $message->{'dest_ip'} = $self->_anonymize_ip( $message->{'dest_ip'} );
        
    }

    return $finished_messages;
}

1;
