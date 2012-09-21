package Tapper::CLI::Host;

use 5.010;
use warnings;
use strict;

use Tapper::Model 'model';
use YAML::XS;

=head1 NAME

Tapper::CLI::Host - Tapper - host related commands for the tapper CLI

=head1 SYNOPSIS

This module is part of the Tapper::CLI framework. It is supposed to be
used together with App::Rad. All following functions expect their
arguments as $c->options->{$arg}.

    use App::Rad;
    use Tapper::CLI::Host;
    Tapper::CLI::Host::setup($c);
    App::Rad->run();

=head1 FUNCTIONS

=head2

Generate a feature summary for a given host. This summary only includes
key_word, socket_type and revision. These are the most important
information and having all features would make a to long list. These
features are concatenated together with commas.

@param host object

@return string - containing features

=cut

sub host_feature_summary
{
        my ($host) = @_;

        return join(",",
                    map { $_->value }
                    sort { $a->entry cmp $b->entry }
                    grep { $_->entry =~ /^(key_word|socket_type|revision)$/ }
                    $host->features->all
                   );
}


=head2 print_hosts_verbose

=cut

sub print_hosts_verbose
{
        my ($hosts) = @_;
        my %max = (
                   name    => 4,
                   features => 10,
                   comment => 7,
                   queue   => 0,
                  );
 HOST:
        foreach my $host ($hosts->all) {
                my $features = host_feature_summary($host);
                $max{name}    = length($host->name) if length($host->name) > $max{name};
                $max{features} = length($features) if length($features) > $max{features};
                $max{comment} = length($host->comment) if length($host->comment) > $max{comment};
                next HOST if not $host->queuehosts->count;
                foreach my $queuehost ($host->queuehosts->all) {
                        $max{queue} = length($queuehost->queue->name) if length($queuehost->queue->name) > $max{queue};
                }
        }
        my ($name_length, $feature_length, $comment_length, $queue_length) = ($max{name}, $max{features}, $max{comment}, $max{queue});

        # use printf to get the wanted field width
        printf ("%5s | %${name_length}s | %-${feature_length}s | %11s | %10s | %${comment_length}s | Queues\n", 'ID', 'Name', 'Features', 'Active', 'Testrun ID', 'Comment');
        say "="x(5+$name_length+$feature_length+11+length('Testrun ID')+$comment_length+length('Queues')+6*length(' | '));


        foreach my $host ($hosts->all) {
                my ($name_length, $feature_length, $queue_length) = ($max{name}, $max{features}, $max{queue});
                my $testrun_id = 'unknown id';
                if (not $host->free) {
                        my $job_rs = model('TestrunDB')->resultset('TestrunScheduling')->search({host_id => $host->id, status => 'running'});
                        $testrun_id = $job_rs->first->testrun_id if $job_rs->count;
                }
                my $features = host_feature_summary($host);
                my $output = sprintf("%5d | %${name_length}s | %-${feature_length}s | %11s | %10s | %${comment_length}s | ",
                                     $host->id,
                                     $host->name,
                                     $features,
                                     $host->is_deleted ? 'deleted' : ( $host->active ? 'active' : 'deactivated' ),
                                     $host->free   ? 'free'   : "$testrun_id",
                                     $host->comment,
                                    );
                if ($host->queuehosts->count) {
                        $output .= join ", ", map {$_->queue->name} $host->queuehosts->all;
                }
                say $output;
        }
}


=head2 select_hosts

=cut

sub select_hosts
{
        my ($opt) = @_;
        my %options= (order_by => 'name');
        my %search;
        $search{active}     = 1 if $opt->{active};
        $search{is_deleted} = {-in => [ 0, undef ] } unless $opt->{all};
        $search{free}   = 1 if $opt->{free};

        # ignore all options if host is requested by name
        %search = (name   => $opt->{name}) if $opt->{name};

        if ($opt->{queue}) {
                my @queue_ids       = map {$_->id} model('TestrunDB')->resultset('Queue')->search({name => {-in => [ @{$opt->{queue}} ]}});
                $search{queue_id}   = { -in => [ @queue_ids ]};
                $options{join}      = 'queuehosts';
                $options{'+select'} = 'queuehosts.queue_id';
                $options{'+as'}     = 'queue_id';
        }
        my $hosts = model('TestrunDB')->resultset('Host')->search(\%search, \%options);
        return $hosts;
}

=head2 print_hosts_yaml

Print given host with all available information in YAML.

@param host object

=cut

sub print_hosts_yaml
{
        my ($hosts) = @_;
        while (my $host = $hosts->next ) {
                my %host_data = (name       => $host->name,
                                 comment    => $host->comment,
                                 free       => $host->free,
                                 active     => $host->active,
                                 is_deleted => $host->is_deleted,
                                 host_id    => $host->id,
                                 );
                my $job = $host->testrunschedulings->search({status => 'running'})->first; # this should always be only one
                if ($job) {
                        $host_data{running_testrun} = $job->testrun->id;
                        $host_data{running_since}   = $job->testrun->starttime_testrun->iso8601;
                }

                if ($host->queuehosts->count > 0) {
                        my @queues = map {$_->queue->name} $host->queuehosts->all;
                        $host_data{queues} = \@queues;
                }

                my %features;
                foreach my $feature ($host->features->all) {
                        $features{$feature->entry} = $feature->value;
                }
                $host_data{features} = \%features;

                print YAML::XS::Dump(\%host_data);
        }
        return;
}

=head2 listhost

List hosts matching given criteria.

=cut

sub listhost
{
        my ($c) = @_;
        $c->getopt( 'free', 'name=s@', 'active', 'queue=s@', 'all|a', 'verbose|v', 'yaml', 'help|?' );
        if ( $c->options->{help} ) {
                say STDERR "$0 host-list [ --verbose|v ] [ --free ] | [ --name=s ]  [ --active ] [ --queue=s@ ] [ --all|a] [ --yaml ]";
                say STDERR "    --verbose      Show all available information; without only show names";
                say STDERR "    --free         List only free hosts";
                say STDERR "    --name         Find host by name, implies verbose";
                say STDERR "    --active       List only active hosts";
                say STDERR "    --queue        List only hosts bound to this queue";
                say STDERR "    --all          List all hosts, even deleted ones";
                say STDERR "    --help         Print this help message and exit";
                say STDERR "    --yaml         Print information in YAML format, implies verbose";
                exit -1;
        }
        my $hosts = select_hosts($c->options);

        if ($c->options->{yaml}) {
                print_hosts_yaml($hosts);
        } elsif ($c->options->{verbose}) {
                print_hosts_verbose($hosts);
        } else {
                foreach my $host ($hosts->all) {
                        say sprintf("%10d | %s", $host->id, $host->name);
                }
        }

        return;
}


=head2 host_deny

Don't use given hosts for testruns of this queue.

=cut

sub host_deny
{
        my ($c) = @_;
        $c->getopt( 'host=s@','queue=s@', ,'off','help|?' );
        if ( $c->options->{help} or not (@{$c->options->{host} ||  []} and $c->options->{queue} )) {
                say STDERR "At least one queuename has to be provided!" unless @{$c->options->{queue} || []};
                say STDERR "At least one hostname has to be provided!" unless @{$c->options->{host} || []};
                say STDERR "$0 host-deny  --host=s@  --queue=s@ --off";
                say STDERR "    --host         Deny this host for testruns of all given queues";
                say STDERR "    --queue        Deny this queue to put testruns on all given hosts";
                say STDERR "    --off          Remove previously installed denial of host/queue combination";
                exit -1;
        }

        my @queue_results; my @host_results;
        foreach my $queue_name ( @{$c->options->{queue}}) {
                my $queue_r = model('TestrunDB')->resultset('Queue')->search({name => $queue_name})->first;
                die "No such queue: '$queue_name'" unless $queue_r;
                push @queue_results, $queue_r;
        }
        foreach my $host_name ( @{$c->options->{host}}) {
                my $host_r = model('TestrunDB')->resultset('Host')->search({name => $host_name})->first;
                die "No such host: '$host_name'" unless $host_r;
                push @host_results, $host_r;
        }

        foreach my $queue_r (@queue_results) {
                foreach my $host_r (@host_results) {
                        if ($c->options->{off}) {
                                my $deny_r = model('TestrunDB')->resultset('DeniedHost')->search({queue_id => $queue_r->id,
                                                                                                  host_id  => $host_r->id,
                                                                                                 })->first;
                                $deny_r->delete if $deny_r;
                        } else {
                                model('TestrunDB')->resultset('DeniedHost')->new({queue_id => $queue_r->id,
                                                                                  host_id  => $host_r->id,
                                                                                 })->insert;
                        }
                }
        }
        return;
}

=head2 host_bind

Bind given hosts to given queues.

=cut

sub host_bind
{
        my ($c) = @_;
        $c->getopt( 'host=s@','queue=s@', ,'off','help|?' );
        if ( $c->options->{help} or not (@{$c->options->{host} ||  []} and $c->options->{queue} )) {
                say STDERR "At least one queuename has to be provided!" unless @{$c->options->{queue} || []};
                say STDERR "At least one hostname has to be provided!" unless @{$c->options->{host} || []};
                say STDERR "$0 host-bind  --host=s@  --queue=s@ --off";
                say STDERR "    --host         Bind this hosts to all given queues (can be given multiple times)";
                say STDERR "    --queue        Bind all given hosts to this queue (can be given multiple times)";
                say STDERR "    --off          Remove previously installed host/queue bindings";
                exit -1;
        }

        my @queue_results; my @host_results;
        foreach my $queue_name ( @{$c->options->{queue}}) {
                my $queue_r = model('TestrunDB')->resultset('Queue')->search({name => $queue_name})->first;
                die "No such queue: '$queue_name'" unless $queue_r;
                push @queue_results, $queue_r;
        }
        foreach my $host_name ( @{$c->options->{host}}) {
                my $host_r = model('TestrunDB')->resultset('Host')->search({name => $host_name})->first;
                die "No such host: '$host_name'" unless $host_r;
                push @host_results, $host_r;
        }

        foreach my $queue_r (@queue_results) {
                foreach my $host_r (@host_results) {
                        if ($c->options->{off}) {
                                my $bind_r = model('TestrunDB')->resultset('QueueHost')->search({queue_id => $queue_r->id,
                                                                                                host_id  => $host_r->id,
                                                                                               })->first;
                                $bind_r->delete if $bind_r;
                        } else {
                                model('TestrunDB')->resultset('QueueHost')->new({queue_id => $queue_r->id,
                                                                                  host_id  => $host_r->id,
                                                                                 })->insert;
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
        $c->register('host-list', \&listhost,  'Show all hosts matching a given condition');
        $c->register('host-deny', \&host_deny, 'Setup or remove forbidden host/queue combinations');
        $c->register('host-bind', \&host_bind, 'Setup or remove host/queue bindings');
        if ($c->can('group_commands')) {
                $c->group_commands('Host commands', 'host-list', );
                $c->group_commands('Host commands', 'host-bind', );
                $c->group_commands('Host commands', 'host-deny', );
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
