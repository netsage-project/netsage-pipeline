package GRNOC::NetSage::Deidentifier::FlowFilter;

use strict;
use warnings;

use Moo;

extends 'GRNOC::NetSage::Deidentifier::Pipeline';

use GRNOC::Log;
use GRNOC::Config;

use Data::Validate::IP;
use Net::IP;
use Digest::SHA;
use POSIX;
use utf8;

use Data::Dumper;


### internal attributes ###

has handler => ( is => 'rwp');

### constructor builder ###

sub BUILD {

    my ( $self ) = @_;

    my $config_obj = $self->config;
    my $config = $config_obj->get('/config');
    warn "config: " . Dumper $config;
    #my $anon = $config->{'deidentification'};
    #my $ipv4_bits = $config->{'deidentification'}->{'ipv4_bits_to_strip'};
    #my $ipv6_bits = $config->{'deidentification'}->{'ipv6_bits_to_strip'};
    #$self->_set_ipv4_bits_to_strip( $ipv4_bits );
    #$self->_set_ipv6_bits_to_strip( $ipv6_bits );
    $self->_set_handler( sub { $self->_filter_messages(@_) } );

    return $self;
}

### private methods ###

# expects an array of data for it to filter
# returns the filtered array
sub _filter_messages {
    my ( $self, $caller, $messages ) = @_;

    my $finished_messages = $messages;

    my $tmp = 0;
    foreach my $message ( @$messages ) {
        my $src_ip = $message->{'meta'}->{'src_ip'};
        my $dst_ip = $message->{'meta'}->{'dst_ip'};
        my $id = $self->_generate_id( $message );
        $message->{'meta'}->{'id'} = $id;
        $message->{'meta'}->{'src_ip'} = $self->_deidentify_ip( $src_ip );
        $message->{'meta'}->{'dst_ip'} = $self->_deidentify_ip( $dst_ip );

        $message->{'start'} = round( $message->{'start'} );
        $message->{'end'} = round( $message->{'end'} );
        #$message->{'values'}->{'duration'} = round( $message->{'values'}->{'duration'} );
        # perform a couple other necessary manipulations
        warn " message: " . Dumper $message if $tmp == 0;
        $tmp++;
    }

    return $finished_messages;
}

sub round {
    my $input = shift;
    return floor( $input );
}

# generates a unique id based on required fields
sub _generate_id {
    my ( $self, $message ) = @_;
    my @fields = ( 'src_ip', 'dst_ip', 'src_port', 'dst_port', 'protocol' );
    @fields = sort @fields;
    my @required = ();
    my $hash = Digest::SHA->new( 256 );
    my $id_string = '';
    foreach my $field (@fields ) {
        #push @required, $message->{'meta'}->{$field};
        warn "required field not found: $field " if not defined $message->{'meta'}->{$field};
        my $value = $message->{'meta'}->{$field};
        $id_string .= $value;
        $hash->add( $value );

    }
    return $hash->hexdigest();
}


1;

