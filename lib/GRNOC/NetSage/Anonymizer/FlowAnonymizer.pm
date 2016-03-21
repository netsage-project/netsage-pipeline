package GRNOC::NetSage::Anonymizer::FlowAnonymizer;

use strict;
use warnings;

use Moo;

extends 'GRNOC::NetSage::Anonymizer::Pipeline';

use GRNOC::Log;
use GRNOC::Config;

use Data::Validate::IP;
use Net::IP;
use Digest::SHA;

use Data::Dumper;


### internal attributes ###
            
has handler => ( is => 'rwp');

### constructor builder ###

sub BUILD {

    my ( $self ) = @_;

    my $config = $self->config;
    warn "config: " . Dumper $config->get('/config');
    $self->_set_handler( sub { $self->_anonymize_messages(@_) } );

    return $self;
}

### private methods ###

# expects an array of data for it to anonymize
# returns the anonymized array
sub _anonymize_messages {
    # TODO: the actual anonymization in a better way
    my ( $self, $caller, $messages ) = @_;

    my $finished_messages = $messages;

    foreach my $message ( @$messages ) {
        my $src_ip = $message->{'meta'}->{'src_ip'};
        my $dst_ip = $message->{'meta'}->{'dst_ip'};
        my $id = $self->_generate_id( $message );
        $message->{'meta'}->{'id'} = $id;
        $message->{'meta'}->{'src_ip'} = $self->_anonymize_ip( $src_ip );
        $message->{'meta'}->{'dst_ip'} = $self->_anonymize_ip( $dst_ip );
    }

    return $finished_messages;
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

    #my $src_ip = $message->{'meta'}->{'src_ip'};
    #my $dst_ip = $message->{'meta'}->{'dst_ip'};
    #my $src_port = $message->{'meta'}->{'src_port'};
    #my $dst_port = $message->{'meta'}->{'dst_port'};
    #my $protocol = $message->{'meta'}->{'protocol'};


}

# anonymizes an individual ip
sub _anonymize_ip {
    my ( $self, $ip ) = @_;
    my $cleaned;

    if ( is_ipv4($ip) ) {
        my @bytes = split(/\./, $ip);
        $cleaned = join('.', $bytes[0], $bytes[1], 'xxx', 'yyy' );

    } elsif ( is_ipv6($ip) ) {
        my $ip_obj = Net::IP->new( $ip );
        my $long = $ip_obj->ip();
        my @bytes = split(/:/, $long);
        # drop have the bytes
        my $num_to_remove = @bytes / 2; 
        my @new_bytes = splice @bytes, 0, $num_to_remove;
        for( my $i=0; $i<$num_to_remove; $i++ ) {
            push @new_bytes, 'x';
        }
        $cleaned = join(':', @new_bytes);

    } else {
        $self->logger->warn('ip address is neither ipv4 or ipv6 ' . $ip);

    }

    if ( not defined $cleaned ) {
        warn "IP was NOT CLEANED. setting blank";
        $cleaned = '';
    }

    

    return $cleaned;

}

1;
