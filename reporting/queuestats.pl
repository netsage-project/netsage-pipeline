#!/usr/bin/perl

use warnings;
use strict;

use Date::Format;
use JSON::XS;
use File::Find::Rule;
use Data::Dumper;

my $day = "day/";
my $month = "rabbitstats/2016/10";

my @subdirs = sort File::Find::Rule->directory->in( $month );
my @queues = ( "netsage_deidentifier_raw", "netsage_deidentifier_stitched", "netsage_deidentifier_deidentified", "netsage_deidentifier_tagged"  );
my @values = ( "publish", "ack", "deliver", "redeliver" );

binmode STDOUT, ":utf8";
use utf8;
my $json = JSON::XS->new();

my $results = [];

foreach my $subdir (@subdirs) {
    # find all the .pm files in @INC
    my @files = File::Find::Rule->file()
        ->name( '*.json' )
        ->in( $subdir );
    my @sorted = sort @files;
    #warn Dumper @sorted;

    my $first = $sorted[0];
    my $last = $sorted[-1];

    #warn "first: $first; last: $last";
    my @json_files = ();
    push @json_files, $first;
    push @json_files, $last;
    my $prev_values = {};

    foreach my $file ( @json_files ) {
        my $json_data;
        {
            local $/; #Enable 'slurp' mode
            open my $fh, "<", $file or die "could not open file: $?";
            $json_data = <$fh>;
            close $fh;
        }

        my $data;
        $data = $json->decode( $json_data );
        #warn "data: " . Dumper $data;
        my $status = $data->{'rabbit_status'};
        my $ts = $data->{'timestamp'};
        foreach my $queue ( @queues ) {
            my ($queue_info) = grep { $_->{'name'} eq $queue } @$status;
#warn "queue $queue: " . Dumper $queue_info;
            my $message_stats = $queue_info->{'message_stats'};
                my $row = {};
            foreach my $value ( @values ) {
                $row->{'queue'} = $queue;
                $row->{'ts'} = $ts;
                $row->{'file'} = $file;
                $row->{'subdir'} = $subdir;
                my $val = $message_stats->{ $value };
                $row->{ $value } = $val;
                #warn "$value: $val";
                if ( defined $prev_values->{$value} ) {
                    #warn "diff to previous: " . ($val - $prev_values->{$value} );

                }
                $prev_values->{$value} = $val;
            }
                push @$results, $row;
        }

    }
}

warn "results: " . Dumper $results;

foreach my $subdir ( @subdirs ) {
    warn $subdir;
    my $min = {};
    my $max = {};
    foreach my $queue ( @queues ) {
        #warn "queue: $queue";
        # get all results for this subdir
        my $res = [ grep { $_->{'subdir'} =~ /^\Q$subdir/ } @$results ];
        #my (#res = grep { $_->{'subdir'} eq $subdir } @$results;
        foreach my $result ( @$res ) {
            foreach my $value ( @values ) {
                # find min values
                next if ( $result->{"queue"} ne $queue );
                if ( ( not defined $min->{ $queue . "_" . $value } && $result->{"queue"} eq $queue ) || ( $result->{ $value } < $min->{ $queue . "_" . $value } ) ) {
                    $min->{ $queue . "_" . $value } = $result->{ $value };
                    $min->{ $queue . "_ts" } = $result->{ 'ts' };
                }
                # find max values
                if ( ( not defined $max->{ $queue . "_" . $value } ) || ( $result->{ $value } > $max->{ $queue . "_" . $value } ) ) {
                    $max->{ $queue . "_" . $value } = $result->{ $value };
                    $max->{ $queue . "_ts" } = $result->{ 'ts' };
                }

            }


        }
        #warn "subdir: $subdir\nmin=" . Dumper ( $min ) . "\nmax: " . Dumper $max;
        print "\t$queue\n";
        foreach my $key ( keys %$min ) {
            #warn "key: $key";
            my $minval = $min->{ $key };
            my $maxval = $max->{ $key };
            if ( $key =~ /\Q$queue\E/ ) {
                $key =~ s/\Q$queue\E_//g;
            } else {
                next;
            }
            print "\t\t$key: " . ( $maxval - $minval ) . "\n";


        }


    }
}
