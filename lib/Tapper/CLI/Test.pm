package Tapper::CLI::Test;

# Note: the correct name would be "Tapper::CLI::Testrun". This module
# still exists and is needed for the old tapper-testrun commands. As soon
# as all these commands are moved to App::Rad please rename the module.


use 5.010;
use warnings;
use strict;

use Tapper::Model 'model';
use YAML::XS;

=head1 NAME

Tapper::CLI::Test - Tapper - testrun related commands for the tapper CLI

=head1 SYNOPSIS

This module is part of the Tapper::CLI framework. It is supposed to be
used together with App::Rad. All following functions expect their
arguments as $c->options->{$arg} unless otherwise stated.

    use App::Rad;
    use Tapper::CLI::Test;
    Tapper::CLI::Test::setup($c);
    App::Rad->run();

=head1 FUNCTIONS

=cut

sub print_testrun
{
        my ($testrun) = @_;

        print "\n",'*'x80,"\n\n";
        say "id: ",$testrun->id;
        say "topic: ", $testrun->topic_name;
        say "shortname: ",$testrun->shortname if $testrun->shortname;
        if (not $testrun->testrun_scheduling) {
                say "Old testrun with no scheduling information";
                return;
        }
        say "state: ",$testrun->testrun_scheduling->status;
        say "queue: ",$testrun->testrun_scheduling->queue->name;
        if ($testrun->testrun_scheduling->status eq "schedule") {
                if ($testrun->testrun_scheduling->requested_hosts->count) {
                        print "requested hosts: ";
                        say join ",", map {$_->host->name} $testrun->testrun_scheduling->requested_hosts->all;
                }
        } else {
                say "used host: ", $testrun->testrun_scheduling->host->name if $testrun->testrun_scheduling->host;
        }
        say "auto rerun: ", $testrun->testrun_scheduling->auto_rerun ? 'yes' : 'no';
        print "precondition_ids: ";
        if ($testrun->ordered_preconditions) {
                say join ", ", map {$_->id} $testrun->ordered_preconditions;
        } else {
                say "None";
        }
}


=head2 testrun_update

Update values of an existing testrun.

=cut

sub testrun_update
{
        my ($c) = @_;
        $c->getopt( 'id=i@','status=s', 'auto-rerun!','help|?', 'verbose|v' );
        if ( $c->options->{help} or not $c->options->{id}) {
                say STDERR "Please set at least one testrun id with --id!" unless @{$c->options->{id}};
                say STDERR "Please set an update action" unless ($c->options->{state} or defined $c->options->{"auto-rerun"});
                say STDERR "$0 testrun-update --id=s@ --status=s --auto_rerun --no-auto-rerun --verbose|v [--help|?]";
                say STDERR "    --id            Id of the testrun to update, can be given multiple times";
                say STDERR "    --status        Set testrun to given status, can be one of 'prepare', 'schedule', 'finished'.";
                say STDERR "    --auto-rerun    Activate auto-rerun on testrun. ";
                say STDERR "    --no-auto-rerun Activate auto-rerun on testrun";
                say STDERR "    --verbose|v     Print new state of testrun (will only print id of updated testruns without)";
                say STDERR "    --help|?        Print this help message and exit";
                exit -1;
        }

 ID:
        foreach my $testrun_id (@{$c->options->{id}}) {
                my $testrun = model('TestrunDB')->resultset('Testrun')->find($testrun_id);
                if (not $testrun) {
                        say STDERR "Testrun with id $testrun_id not found. Skipping!";
                        next ID;
                }
                if (not ($testrun->testrun_scheduling->status eq 'prepare' or
                         $testrun->testrun_scheduling->status eq 'schedule')
                   )
                {
                        say STDERR "Can only update testruns in state 'schedule' and 'finished'. Updating testruns in other states will break something. Please consider tapper-testrun rerun";
                        next ID;
                }

                if ($c->options->{status}) {
                        $testrun->testrun_scheduling->status($c->options->{status});
                        $testrun->testrun_scheduling->update;
                }
                if (defined($c->options->{"auto-rerun"})) {
                        $testrun->testrun_scheduling->auto_rerun($c->options->{"auto-rerun"});
                        $testrun->testrun_scheduling->update;
                }
                if ($c->options->{verbose}) {
                        print_testrun($testrun);
                } else {
                        say STDERR $testrun_id;
                }
        }

}

=head2 setup

Initialize the testplan functions for tapper CLI

=cut

sub setup
{
        my ($c) = @_;
        $c->register('testrun-update',  \&testrun_update,  'Update an existing testrun');
        if ($c->can('group_commands')) {
                $c->group_commands('Testrun commands', 'testrun-update', );
        }
        return;
}

1; # End of Tapper::CLI
