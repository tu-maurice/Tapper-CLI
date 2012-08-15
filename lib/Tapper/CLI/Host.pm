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


=head2 setup

Initialize the testplan functions for tapper CLI

=cut

sub setup
{
        my ($c) = @_;
        $c->register('host-list', \&listhost, 'Show all hosts matching a given condition');
        if ($c->can('group_commands')) {
                $c->group_commands('Host commands', 'host-list', );
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
