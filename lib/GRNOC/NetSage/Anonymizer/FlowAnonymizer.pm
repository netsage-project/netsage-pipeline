package GRNOC::NetSage::Anonymizer::FlowAnonymizer;

use strict;
use warnings;


use Moo;

use GRNOC::NetSage::Anonymizer::Pipeline;
use GRNOC::Log;
use GRNOC::Config;

use Data::Validate::IP;
use Net::IP;

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


### constructor builder ###

sub BUILD {

    my ( $self ) = @_;

    # create and store logger object
    my $grnoc_log = GRNOC::Log->new( config => $self->logging_file );
    my $logger = GRNOC::Log->get_logger();

    $self->_set_logger( $logger );

    # create the Pipeline object, which handles the Rabbit queues

    my $pipeline = GRNOC::NetSage::Anonymizer::Pipeline->new(
        config_file => $self->config_file,
        logging_file => $self->logging_file,
        input_queue_name => 'tagged',
        output_queue_name => 'anonymized',
        handler => sub { $self->_anonymize_messages(@_) },
        process_name => 'netsage_anonymizer',
    );
    $self->_set_pipeline( $pipeline );

    return $self;
}

### public methods ###

sub start {

    my ( $self ) = @_;
    return $self->pipeline->start();

}

### private methods ###

# expects an array of data for it to anonymize
# returns the anonymized array
sub _anonymize_messages {
    # TODO: the actual anonymization in a better way
    my ( $self, $caller, $messages ) = @_;

    my $finished_messages = $messages;

    foreach my $message ( @$messages ) {
        $message->{'src_ip'} = $self->_anonymize_ip( $message->{'src_ip'} );
        $message->{'dest_ip'} = $self->_anonymize_ip( $message->{'dest_ip'} );
    }

    return $finished_messages;
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

    

    return $cleaned;

}

1;
