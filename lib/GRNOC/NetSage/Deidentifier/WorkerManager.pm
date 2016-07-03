package GRNOC::NetSage::Deidentifier::WorkerManager;

use Moo;
use Types::Standard qw( Str Bool );

# this one needs to change
#use GRNOC::NetSage::Deidentifier::WorkerManager::Worker;
#use GRNOC::NetSage::Deidentifier::Pipeline;
use GRNOC::NetSage::Deidentifier::FlowTagger;

use GRNOC::Config;
use GRNOC::Log;

use Parallel::ForkManager;
use Proc::Daemon;

use Data::Dumper;

### required attributes ###

has config_file => ( is => 'ro',
                     isa => Str,
                     required => 1 );

has logging_file => ( is => 'ro',
                      isa => Str,
                      required => 1 );

has worker => ( is => 'ro',
                required => 1 );

has process_name => ( is => 'ro',
                      required => 1 );

### optional attributes ###

has daemonize => ( is => 'ro',
                   isa => Bool,
                   default => 1 );

has task_type => ( is => 'rwp' );

### private attributes ###

has config => ( is => 'rwp' );

has logger => ( is => 'rwp' );

has children => ( is => 'rwp',
                  default => sub { [] } );

has flow_cache => ( is => 'rwp',
                    default => sub { {} } );

has knot => ( is => 'rwp' );

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

    return $self;
}

sub _init_cache {
    my $self = shift;

    my %flow_cache = (); # $self->flow_cache;
    #$flow_cache{'test'} = 'value';

    my $glue = 'flow';

    #IPC::Shareable->clean_up_all;
    my %options = (
        create    => 0,
        exclusive => 0,
        mode      => 0644,
        destroy   => 0
    );

    #IPC::Shareable->clean_up;
    #IPC::Shareable->clean_up_all;

    #my $knot = tie %flow_cache, 'IPC::Shareable', $glue, { %options } or die ("failed to tie cache");

    #warn "getting cache ..." . Dumper %flow_cache;
    #(tied %flow_cache)->shlock;
    #$flow_cache{'locked_adding'} = 'w00t!';
    #%flow_cache = (
    #    'test2' => 'wow!'
    #);
    #(tied %flow_cache)->shunlock;
    #warn "getting cache ..." . Dumper %flow_cache;

    #$self->_set_flow_cache( \%flow_cache );
    #$self->_set_knot( $knot );

}

### public methods ###

sub start {

    my ( $self, $task_type ) = @_;

    $self->_set_task_type( $task_type );

    $self->logger->info( 'Starting.' );

    $self->logger->debug( 'Setting up signal handlers.' );

    # setup signal handlers
    $SIG{'TERM'} = sub {

        $self->logger->info( 'Received SIG TERM.' );
        $self->stop();
    };

    $SIG{'HUP'} = sub {

        $self->logger->info( 'Received SIG HUP.' );
    };

    # need to daemonize
    if ( $self->daemonize ) {

        $self->logger->debug( 'Daemonizing.' );

        my $daemon = Proc::Daemon->new( pid_file => $self->config->get( '/config/worker/pid-file' ) );

        my $pid = $daemon->Init();

        # in child/daemon process
        if ( !$pid ) {

            $self->logger->debug( 'Created daemon process.' );

            # change process name
            $0 = "netsage_deidentifier";

            $self->_create_workers();
        }
    }

    # dont need to daemonize
    else {

        $self->logger->debug( 'Running in foreground.' );

        $self->_create_workers();
    }

    return 1;
}

sub stop {

    my ( $self ) = @_;

    $self->logger->info( 'Stopping.' );

    my @pids = @{$self->children};

    $self->logger->debug( 'Stopping child worker processes ' . join( ' ', @pids ) . '.' );

    return kill( 'TERM', @pids );
}

### helper methods ###

sub _build_config {

    my ( $self ) = @_;

    $self->logger->debug( 'Building GRNOC::Config with config file ' . $self->config_file . '.' );

    return GRNOC::Config->new( config_file => $self->config_file,
                               force_array => 0 );
}

sub _create_workers {

    my ( $self ) = @_;

    my $num_processes = $self->config->get( '/config/worker/num-processes' );

    $self->logger->info( "Creating $num_processes child worker processes." );

    $self->_init_cache();

    my %flow_cache = %{ $self->flow_cache };

    my $forker = Parallel::ForkManager->new( $num_processes );

    # keep track of children pids
    $forker->run_on_start( sub {

        my ( $pid ) = @_;

        $self->logger->debug( "Child worker process $pid created." );

        push( @{$self->children}, $pid );
                           } );

    for ( 1 .. $num_processes ) {

        $forker->start() and next;


    #die "done";

        # create worker in this process
        #my $worker = GRNOC::NetSage::Deidentifier::FlowTagger->new( config => $self->config,
        #							      logger => $self->logger,
        #                              config_file => $self->config_file,
        #                              logging_file => $self->logging_file );
        my $worker = $self->worker;

        # this should only return if we tell it to stop via TERM signal etc.
        $worker->start( $self->task_type );

        # exit child process
        $forker->finish();
    }

    $self->logger->debug( 'Waiting for all child worker processes to exit.' );

    # wait for all children to return
    $forker->wait_all_children();

    $self->_set_children( [] );

    #(tied %flow_cache)->remove;

    $self->logger->debug( 'All child workers have exited.' );
}

1;
