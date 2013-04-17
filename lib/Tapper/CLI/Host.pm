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
arguments as $c->options->{$arg} unless otherwise stated.

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
        my ($hosts, $verbosity_level) = @_;

        # calculate width of columns
        my %max = (
                   name      => length('Name'),
                   features  => length ('Features'),
                   comment   => length('Comment'),
                   bindqueue => length('Bound Queues'),
                   denyqueue => length('Denied Queues'),
                   pool      => length('Pool count (used/all)'),
                  );
 HOST:
        foreach my $host ($hosts->all) {
                my $features = host_feature_summary($host);
                $max{name}    = length($host->name) if length($host->name) > $max{name};
                $max{features} = length($features) if length($features) > $max{features};
                $max{comment} = length($host->comment) if length($host->comment) > $max{comment};

                my $tmp_length = length(join ", ", map {$_->queue->name} $host->queuehosts->all);
                $max{bindqueue} = $tmp_length if $tmp_length > $max{bindqueue} ;

                $tmp_length = length(join ", ", map {$_->queue->name} $host->denied_from_queue->all);
                $max{denyqueue} = $tmp_length if $tmp_length > $max{bindqueue} ;
        }

        my ($name_length, $feature_length, $comment_length, $bq_length, $dq_length, $pool_length) =
          ($max{name}, $max{features}, $max{comment}, $max{bindqueue}, $max{denyqueue}, $max{pool});

        # use printf to get the wanted field width
        if ($verbosity_level > 1) {
                printf("%5s | %${name_length}s | %-${feature_length}s | %11s | %10s | %${comment_length}s | %-${bq_length}s | %-${dq_length}s | %-${pool_length}s\n",
                        'ID', 'Name', 'Features', 'Active', 'Testrun ID', 'Comment', 'Bound Queues', 'Denied Queues', 'Pool Count (used/all)');
        } else {
                printf("%5s | %${name_length}s | %-${feature_length}s | %11s | %10s | %${bq_length}s | %${dq_length}s | %-${pool_length}s\n",
                        'ID', 'Name', 'Features', 'Active', 'Testrun ID', 'Bound Queues', 'Denied Queues', 'Pool Count (used/all)');
                $comment_length = 0;
        }
        say "="x(5+$name_length+$feature_length+11+length('Testrun ID')+$comment_length+$bq_length+$dq_length+$pool_length+7*length(' | '));


        foreach my $host ($hosts->all) {
                my ($name_length, $feature_length, $queue_length) = ($max{name}, $max{features}, $max{queue});
                my $testrun_id = 'unknown id';
                if (not $host->free) {
                        my $job_rs = model('TestrunDB')->resultset('TestrunScheduling')->search({host_id => $host->id, status => 'running'});
                        $testrun_id = $job_rs->search({}, {rows => 1})->first->testrun_id if $job_rs->count;
                }
                my $features = host_feature_summary($host);
                my $output = sprintf("%5d | %${name_length}s | %-${feature_length}s | %11s | %10s | ",
                                     $host->id,
                                     $host->name,
                                     $features,
                                     $host->is_deleted ? 'deleted' : ( $host->active ? 'active' : 'deactivated' ),
                                     $host->free   ? 'free'   : "$testrun_id",
                                    );
                  if ($verbosity_level > 1) {
                        $output .= sprintf("%${comment_length}s | ", $host->comment);

                }
                $output .= sprintf("%-${bq_length}s | %-${dq_length}s",
                                   $host->queuehosts->count        ? join(", ", map {$_->queue->name} $host->queuehosts->all) : '',
                                   $host->denied_from_queue->count ? join(", ", map {$_->queue->name} $host->denied_from_queue->all) : ''
                                  );
                $output .= sprintf(" | %-${pool_length}s", $host->is_pool ? ($host->pool_count-$host->pool_free)."/".$host->pool_count : '-');
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
        $search{free}       = 1 if $opt->{free};
        $search{pool_count} = { not => undef } if $opt->{pool};

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
                my $job = $host->testrunschedulings->search({status => 'running'}, {rows => 1})->first; # this should always be only one
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
        $c->getopt( 'free', 'name=s@', 'active', 'queue=s@', 'pool', 'all|a', 'verbose|v+', 'yaml', 'help|?' );
        if ( $c->options->{help} ) {
                say STDERR "$0 host-list [ --verbose|v ] [ --free ] | [ --name=s ] [--pool] [ --active ] [ --queue=s@ ] [ --all|a] [ --yaml ]";
                say STDERR "    --verbose      Increase verbosity level, without show only names, level one shows all but comments, level two shows all including comments";
                say STDERR "    --free         List only free hosts";
                say STDERR "    --name         Find host by name, implies verbose";
                say STDERR "    --active       List only active hosts";
                say STDERR "    --queue        List only hosts bound to this queue";
                say STDERR "    --pool         List only pool hosts, even deleted ones";
                say STDERR "    --all          List all hosts, even deleted ones";
                say STDERR "    --help         Print this help message and exit";
                say STDERR "    --yaml         Print information in YAML format, implies verbose";
                exit -1;
        }
        my $hosts = select_hosts($c->options);

        if ($c->options->{yaml}) {
                print_hosts_yaml($hosts);
        } elsif ($c->options->{verbose}) {
                print_hosts_verbose($hosts, $c->options->{verbose});
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
        $c->getopt( 'host=s@','queue=s@','really' ,'off','help|?' );
        if ( $c->options->{help} or not (@{$c->options->{host} ||  []} and $c->options->{queue} )) {
                say STDERR "At least one queuename has to be provided!" unless @{$c->options->{queue} || []};
                say STDERR "At least one hostname has to be provided!" unless @{$c->options->{host} || []};
                say STDERR "$0 host-deny  --host=s@  --queue=s@ [--off] [--really]";
                say STDERR "    --host         Deny this host for testruns of all given queues";
                say STDERR "    --queue        Deny this queue to put testruns on all given hosts";
                say STDERR "    --off          Remove previously installed denial of host/queue combination";
                say STDERR "    --really       Force denial of host/queue combination even if it does not make sense (e.g. because host is also bound to queue)";
                exit -1;
        }

        my @queue_results; my @host_results;
        foreach my $queue_name ( @{$c->options->{queue}}) {
                my $queue_r = model('TestrunDB')->resultset('Queue')->search({name => $queue_name}, {rows => 1})->first;
                die "No such queue: '$queue_name'" unless $queue_r;
                push @queue_results, $queue_r;
        }
        foreach my $host_name ( @{$c->options->{host}}) {
                my $host_r = model('TestrunDB')->resultset('Host')->search({name => $host_name}, {rows => 1})->first;
                die "No such host: '$host_name'" unless $host_r;
                push @host_results, $host_r;
        }

        foreach my $queue_r (@queue_results) {
        HOST:
                foreach my $host_r (@host_results) {
                        if ($c->options->{off}) {
                                my $deny_r = model('TestrunDB')->resultset('DeniedHost')->search({queue_id => $queue_r->id,
                                                                                                  host_id  => $host_r->id, },
                                                                                                 {rows => 1}
                                                                                                )->first;
                                $deny_r->delete if $deny_r;
                        } else {

                                if ($host_r->queuehosts->search({queue_id => $queue_r->id}, {rows => 1})->first) {
                                        my $msg = 'Host '.$host_r->name.' is bound to from queue '.$queue_r->name;
                                        if ($c->options->{really}) {
                                                say STDERR "SUCCESS: $msg. Will still deny it too, because you requested it.";
                                        } else {
                                                say STDERR "ERROR: $msg. This does not make sense. Will not deny it from the queue. You can override it with --really";
                                                next HOST;
                                        }
                                }
                                # don't deny twice
                                next HOST if $host_r->denied_from_queue->search({queue_id => $queue_r->id}, {rows => 1})->first;
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
        $c->getopt( 'host=s@','queue=s@','really' ,'off','help|?' );
        if ( $c->options->{help} or not (@{$c->options->{host} ||  []} and $c->options->{queue} )) {
                say STDERR "At least one queuename has to be provided!" unless @{$c->options->{queue} || []};
                say STDERR "At least one hostname has to be provided!" unless @{$c->options->{host} || []};
                say STDERR "$0 host-bind  --host=s@  --queue=s@ [--off] [--really]";
                say STDERR "    --host         Bind this hosts to all given queues (can be given multiple times)";
                say STDERR "    --queue        Bind all given hosts to this queue (can be given multiple times)";
                say STDERR "    --off          Remove previously installed host/queue bindings";
                say STDERR "    --really       Force binding host/queue combination even if it does not make sense (e.g. because host is also denied from queue)";
                exit -1;
        }

        my @queue_results; my @host_results;
        foreach my $queue_name ( @{$c->options->{queue}}) {
                my $queue_r = model('TestrunDB')->resultset('Queue')->search({name => $queue_name}, {rows => 1})->first;
                die "No such queue: '$queue_name'" unless $queue_r;
                push @queue_results, $queue_r;
        }
        foreach my $host_name ( @{$c->options->{host}}) {
                my $host_r = model('TestrunDB')->resultset('Host')->search({name => $host_name}, {rows => 1})->first;
                die "No such host: '$host_name'" unless $host_r;
                push @host_results, $host_r;
        }

        foreach my $queue_r (@queue_results) {
                foreach my $host_r (@host_results) {
                        if ($c->options->{off}) {
                                my $bind_r = model('TestrunDB')->resultset('QueueHost')->search({queue_id => $queue_r->id,
                                                                                                 host_id  => $host_r->id },
                                                                                                {rows => 1}
                                                                                               )->first;
                                $bind_r->delete if $bind_r;
                        } else {
                                if ($host_r->denied_from_queue->single({queue_id => $queue_r->id})) {
                                        my $msg = 'Host '.$host_r->name.' is denied from from queue '.$queue_r->name;
                                        if ($c->options->{really}) {
                                                say STDERR "SUCCESS: $msg. Will still deny it too, because you requested it.";
                                        } else {
                                                say STDERR "ERROR: $msg. This does not make sense. Will not bind it to the queue. You can override it with --really";
                                                next HOST;
                                        }
                                }
                                # don't bind twice
                                next HOST if $host_r->queuehosts->search({queue_id => $queue_r->id}, {rows => 1})->first;
                                model('TestrunDB')->resultset('QueueHost')->new({queue_id => $queue_r->id,
                                                                                  host_id  => $host_r->id,
                                                                                 })->insert;
                        }
                }
        }
        return;
}


=head2 host_new

Create a new host.

=cut

sub host_new
{
        my ($c) = @_;
        $c->getopt( 'name=s', 'queue=s@', 'active', 'pool_count=s', 'verbose|v', 'help|?' );
        if ( $c->options->{help} or not $c->options->{name}) {
                say STDERR "Host name missing!" unless $c->options->{name};
                say STDERR "$0 host-new  --name=s [ --queue=s@ ] [--pool_count=s] [--verbose|-v] [--help|-?";
                say STDERR "    --name         Name of the new host)";
                say STDERR "    --queue        Bind host to this queue, can be given multiple times)";
                say STDERR "    --active       Make host active; without it host will be initially deactivated)";
                say STDERR "    --verbose      More verbose output)";
                exit -1;
        }

        if ($c->options->{queue}) {
                foreach my $queue (@{$c->options->{queue}}) {
                        my $queue_rs = model('TestrunDB')->resultset('Queue')->search({name => $queue});
                        if (not $queue_rs->count) {
                                say STDERR "No such queue: $queue";
                                my @queue_names = map {$_->name} model('TestrunDB')->resultset('Queue')->all;
                                say STDERR "Existing queues: ",join ", ",@queue_names;
                        }
                }
        }
        my $host = {
                    name       => $c->options->{name},
                    active     => $c->options->{active},
                    free       => 1,
                    pool_free  => $c->options->{pool_count} ? $c->options->{pool_count} : undef, # need to turn 0 into undef, because 0 makes $host->is_pool true
                   };

        my $newhost = model('TestrunDB')->resultset('Host')->new($host);
        $newhost->insert();
        die "Can't create new host\n" if not $newhost; # actually, on this place DBIC should have died already

        if ($c->options->{queue}) {
                foreach my $queue (@{$c->options->{queue}}) {
                        my $queue_rs   = model('TestrunDB')->resultset('Queue')->search({name => $queue});
                        if (not $queue_rs->count) {
                                $newhost->delete();
                                say STDERR qq(Did not find queue "$queue");
                        }
                        my $queue_host = model('TestrunDB')->resultset('QueueHost')->new({
                                                                                          host_id  => $newhost->id,
                                                                                          queue_id => $queue_rs->search({}, {rows => 1})->first->id,
                                                                                         });
                        $queue_host->insert();
                }
        }
        return $newhost->id;
}

=head2 host_update

Update values of the host other than binding and denying queues.

=cut

sub host_update
{
        my ($c) = @_;
        $c->getopt( 'name=s', 'id=i', 'active!', 'pool_count=s', 'comment=s','verbose|v', 'help|?' );
        if ( $c->options->{help} or not ($c->options->{name} or $c->options->{id})) {
                say STDERR "Please provide name or id of a host!" unless ($c->options->{name} or $c->options->{id});
                say STDERR "$0 host-update  --name=s | --id=i [--pool_count=s] [--active | --noactive] [--comment=s] [--verbose|-v] [--help|-?]";
                say STDERR "    --name         Name of the host";
                say STDERR "    --id           Id of the host; If both id and name are given you can change the name.";
                say STDERR "    --active       Make host active; without it host will be initially deactivated";
                say STDERR "    --pool_count   Update the sum pool count of a host. Empty string make host a nonpool host. This works only if host is deactivated";
                say STDERR "    --active       Make host active";
                say STDERR "    --noactive     Make host non-active";
                say STDERR "    --comment      Update host comment";
                say STDERR "    --verbose|v    More verbose output";
                exit -1;
        }

        if ($c->options->{name} and not $c->options->{id}) {
                my $host = model('TestrunDB')->resultset('Host')->search({name => $c->options->{name}}, {rows => 1})->first;
                if (not  $host) {
                        die "No such host: ", $c->options->{name}, "\n";
                }
                $c->options->{id} = $host->id;
        }

        my $host = model('TestrunDB')->resultset('Host')->find($c->options->{id});
        if (not $host) {
                die "No host with id ", $c->options->{id}, "\n";
        }

        $host->active($c->options->{active})         if defined($c->options->{active});
        $host->name($c->options->{name})             if $c->options->{name};
        $host->comment($c->options->{comment})       if defined($c->options->{comment});
        $host->pool_count($c->options->{pool_count}) if defined($c->options->{pool_count});
        $host->update;
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
        $c->register('host-new',  \&host_new,  'Create a new host by name');
        $c->register('host-update',  \&host_update,  'Update an existing host');
        if ($c->can('group_commands')) {
                $c->group_commands('Host commands', 'host-new', 'host-list', 'host-update', 'host-bind', 'host-deny',  );
        }
        return;
}

1; # End of Tapper::CLI
