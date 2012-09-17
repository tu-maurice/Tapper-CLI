package Tapper::CLI::Queue;

use 5.010;
use warnings;
use strict;

use Tapper::Model 'model';
use YAML::XS;

=head1 NAME

Tapper::CLI::Queue - Tapper - queue related commands for the tapper CLI

=head1 SYNOPSIS

This module is part of the Tapper::CLI framework. It is supposed to be
used together with App::Rad. All following functions expect their
arguments as $c->options->{$arg}.

    use App::Rad;
    use Tapper::CLI::Queue;
    Tapper::CLI::Queue::setup($c);
    App::Rad->run();

=head1 FUNCTIONS


=head2 deny_host

Don't use given hosts for testruns of this queue.

=cut

sub deny_host
{
        my ($c) = @_;
        $c->getopt( 'host=s@','queue=s', 'help|?' );
        if ( $c->options->{help} or not (@{$c->options->{host} ||  []} and $c->options->{queue} )) {
                say STDERR "Required argument 'queue' not given!" unless $c->options->{queue};
                say STDERR "At least one hostname has to be provided!" unless @{$c->options->{host} || []};
                say STDERR "$0 queue-deny-host  --host=s@  --queue=s";
                say STDERR "    --host         Deny this host for testruns of that queue";
                say STDERR "    --queue        Deny host(s) for this queue";
                exit -1;
        }
        my $queue_r = model('TestrunDB')->resultset('Queue')->search({name => $c->options->{queue}})->first;
        die "No such queue: ".$c->options->{queue} if not $queue_r;
        foreach my $job ($queue_r->testrunschedulings->search({status => 'schedule'})->all) {
                foreach my $host (@{$c->options->{host}}) {
                        my $feat = model('TestrunDB')->resultset('TestrunRequestedFeature')->new({
                                                                                                  testrun_id => $job->testrun->id,
                                                                                                  feature => "hostname ne $host",
                                                                                                 });
                        $feat->insert;
                        say "preventing testrun ",$job->testrun->id," from using $host";
                }

        }
        return;
}

=head2 allow_host

Allow given hosts for testruns of given queue.

=cut

sub allow_host
{
        my ($c) = @_;
        $c->getopt( 'host=s@','queue=s', 'help|?' );
        if ( $c->options->{help} or not (@{$c->options->{host} ||  []} and $c->options->{queue} )) {
                say STDERR "Required argument 'queue' not given!" unless $c->options->{queue};
                say STDERR "At least one hostname has to be provided!" unless @{$c->options->{host} || []};
                say STDERR "$0 queue-allow-host  --host=s@  --queue=s";
                say STDERR "    --host         Allow this host for testruns of that queue";
                say STDERR "    --queue        Allow host(s) for this queue";
                exit -1;
        }
        my $queue_r = model('TestrunDB')->resultset('Queue')->search({name => $c->options->{queue}})->first;
        die "No such queue: ".$c->options->{queue} if not $queue_r;
        foreach my $job ($queue_r->testrunschedulings->search({status => 'schedule'})->all) {
                foreach my $host (@{$c->options->{host}}) {
                        my $feat_string = "hostname ne $host";
                        foreach my $feature ($job->requested_features->search({feature => $feat_string})->all) {
                                $feature->delete;
                                say "Allowing $host for testrun ",$job->testrun->id;
                        }
                }

        }
        return;
}


=head2 setup

Initialize the testplan functions for tapper CLI

=cut

sub setup
{
        my ($c) = @_;
        $c->register('queue-deny-host', \&deny_host, q(Don't use given hosts for testruns of this queue.));
        $c->register('queue-allow-host', \&allow_host, q(Allow given hosts for testruns of this queue.));
        if ($c->can('group_commands')) {
                $c->group_commands('Queue commands', 'queue-deny-host', );
                $c->group_commands('Queue commands', 'queue-allow-host', );
        }
        return;
}

=head1 AUTHOR

AMD OSRC Tapper Team, C<< <tapper at amd64.org> >>

=head1 BUGS


=head1 COPYRIGHT & LICENSE

Copyright 2008-2011 AMD OSRC Tapper Team, all rights reserved.

This program is released under the following license: freebsd


=cut

1; # End of Tapper::CLI
