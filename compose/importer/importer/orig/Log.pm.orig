#--------------------------------------------------------------------
#----- Copyright(C) 2015 The Trustees of Indiana University
#--------------------------------------------------------------------
#----- A logging wrapper built on top of Log4perl
#-----
#---------------------------------------------------------------------

package GRNOC::Log;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw( log_debug log_info log_warn log_error );
our @EXPORT_OK = qw ( log log_debug log_info log_warn log_error );

=head1 NAME

GRNOC::Log

=head1 VERSION

Version 1.0.4

=cut

    our $VERSION = '1.0.4';

=head1 SYNOPSIS

GRNOC::Log - Provides an abstraction around logging mechanisms to make 
Logging super easy for developers

=cut

use Log::Log4perl;
use Log::Dispatch::Syslog;

$0 =~ /(.*)/;
$0 = $1;

=head2 new

creates a new GRNOC::Log object given a config file.  Optionally a 
watch option can be specified to make the logger watch the config file
every watch interval and update its configuration based on the config

**Should use this once in an entire application - perl modules should
  not call GRNOC::Log->new **

=cut

sub new{
    my $that = shift;
    my $class = ref($that) || $that;
    
    my %args = (@_);
    my $self = \%args;
    
    if(!defined($self->{'config'}) && !defined($self->{'level'})){
	return undef;
    }

    bless($self,$class);
    $self->{'logger'} = $self->_setup_logger();
   

    return $self;
}

sub _setup_logger{
    my $self = shift;

    if(!defined($self->{'config'})){
	Log::Log4perl::init_once( {"log4perl.rootLogger" => $self->{'level'} . ", STDOUT",
				   "log4perl.appender.STDOUT" => "org.apache.log4j.ConsoleAppender",
				   "log4perl.appender.STDOUT.stderr" => "0",
				   "log4perl.appender.STDOUT.layout" => "Log::Log4perl::Layout::SimpleLayout"
			       } );
    }else{
	
	if(!defined($self->{'watch'})){
	    Log::Log4perl::init_once($self->{'config'});
	  }else{
	      Log::Log4perl::init_and_watch($self->{'config'},$self->{'watch'});  
	    }
    }
}

=head2 get_logger

This returns a context specific logger for the caller

**This should be called by perl modules and anything else
  in need of a logging object**

=cut

sub get_logger{
    my ($pkg, $filename, $line) = caller;
    return Log::Log4perl->get_logger($pkg);
}

=head2 log_error

logs an error message
    log_error("this is an error message");

=cut

sub log_error{
    my @log_details = @_;
    my ($pkg, $filename, $line) = caller;
    local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
    my $logger = Log::Log4perl->get_logger($pkg);
    
    $logger->error(@log_details);   

}

=head2 log_warn

logs a warning message
    log_warn"this is a warn message");

=cut

sub log_warn{
    my @log_details = @_;
    my ($pkg, $filename, $line) = caller;
    local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
    my $logger = Log::Log4perl->get_logger($pkg);

    $logger->warn(@log_details);

}

=head2 log_info

logs an info message
    log_info("this is an info message");

=cut

sub log_info{
    my @log_details = @_;
    my ($pkg, $filename, $line) = caller;
    local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
    my $logger = Log::Log4perl->get_logger($pkg);

    $logger->info(@log_details);

}

=head2 log_debug

logs a debug message
    log_debug this is a debug message");

=cut


sub log_debug{
    my @log_details = @_;
    my ($pkg, $filename, $line) = caller;
    local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
    my $logger = Log::Log4perl->get_logger($pkg);

    $logger->debug(@log_details);

}

=head2 log 

Logs a message at the specified severity

 ex. 
   log(severity => 'error',
       message => 'An error occured');

=cut

sub log{
    my %args = @_;
    
    #do some validation
    if(!defined($args{'severity'}) || $args{'severity'} eq ''){
	return;
    }
    my $severity = $args{'severity'};
    
    if(!defined($args{'message'})){
	return;
    }
    my $message = $args{'message'};

    #find the right logger
    my ($pkg, $filename, $line) = caller;
    local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
    my $logger = Log::Log4perl->get_logger($pkg);

    if ( $severity eq "info" ) {
	$logger->info($message);
    } elsif ( $severity eq "warn" ) {
	$logger->warn($message);
    } elsif ( $severity eq "error" ) {
	$logger->get_logger()->error($message);
    } elsif ( $severity eq "fatal" ) {
	$logger->fatal($message);
    } elsif ( $severity eq "debug" ) {
	$logger->debug($message);
    }else{
	$logger->error("Unknown Log level: " . $severity . "! Defaulting to Error: " . $message);
    }

}

1;
