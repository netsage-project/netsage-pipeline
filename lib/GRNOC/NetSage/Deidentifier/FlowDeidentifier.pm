package GRNOC::NetSage::Deidentifier::FlowDeidentifier;

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

has ipv4_bits_to_strip => ( is => 'rwp', default => 8 );
has ipv6_bits_to_strip => ( is => 'rwp', default => 64 );

### constructor builder ###

sub BUILD {

    my ( $self ) = @_;

    my $config = $self->config;
    #warn "config: " . Dumper $config;
    my $anon = $config->{'deidentification'};
    my $ipv4_bits = $config->{'deidentification'}->{'ipv4_bits_to_strip'};
    my $ipv6_bits = $config->{'deidentification'}->{'ipv6_bits_to_strip'};

    $self->_set_ipv4_bits_to_strip( $ipv4_bits );
    $self->_set_ipv6_bits_to_strip( $ipv6_bits );
    $self->_set_handler( sub { $self->_deidentify_messages(@_) } );

    return $self;
}

### private methods ###

# expects an array of data for it to deidentify
# returns the deidentified array
sub _deidentify_messages {
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
        #warn " message: " . Dumper $message if $tmp == 0;
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

# deidentifies an individual ip
sub _deidentify_ip {
    my ( $self, $ip ) = @_;
    my $cleaned;


    if ( is_ipv4($ip) ) {
        my @bytes = split(/\./, $ip);
        my $total_bytes = @bytes;
        my $num_to_remove = $self->ipv4_bits_to_strip / 8; 
        my $num_to_keep = $total_bytes - $num_to_remove;
        my @new_bytes = splice @bytes, 0, $num_to_keep;
        for ( my $i=0; $i<$num_to_remove; $i++) {
            push @new_bytes, 'x';
        }
        $cleaned = join('.', @new_bytes );

    } elsif ( is_ipv6($ip) ) {
        my $ip_obj = Net::IP->new( $ip );
        my $long = $ip_obj->ip();
        #warn "$long\tlong";
        my @bytes = split(/:/, $long);
        my $total_bytes = @bytes;
        # Divide bits by 8 to get bytes; divide by 2 as there are 2 bytes per group
        my $num_to_remove = $total_bytes - $self->ipv6_bits_to_strip / 8 / 2; 
        my @new_bytes = splice @bytes, 0, $num_to_remove;
        for( my $i=0; $i<$total_bytes - $num_to_remove; $i++ ) {
            push @new_bytes, 'x';
        }
        $cleaned = join(':', @new_bytes);

    } else {
        $self->logger->warn('ip address is neither ipv4 or ipv6 ' . $ip);

    }

    if ( not defined $cleaned ) {
        warn "IP $ip was NOT CLEANED. setting blank";
        $cleaned = '';
    }

    return $cleaned;

}

1;
