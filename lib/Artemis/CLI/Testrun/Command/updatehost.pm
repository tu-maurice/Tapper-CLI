package Artemis::CLI::Testrun::Command::updatehost;

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Artemis::Model 'model';
use Artemis::CLI::Testrun;

sub abstract {
        'Update an existing host'
}


my $options =  {
                "verbose"          => { text => "some more informational output", short=> 'v' },
                "id"               => { text => "INT; change host with this id; required", type => 'string'},
                "name"             => { text => "TEXT; update name",    type => 'string' },
                "active"           => { text => "set active flag to this value, prepend with not to unset", type => 'withno' },
                "addqueue"         => { text => "TEXT; Bind host to named queue without deleting other bindings (queue has to exists already)", type => 'manystring'},
                "delqueue"         => { text => "TEXT; delete queue from this host's bindings, empty string means 'all bindings'", type => 'optmanystring'},
               };

sub opt_spec {
        my @opt_spec;
        foreach my $key (keys %$options) {
                my $pushkey = $key;
                $pushkey    = $pushkey."|".$options->{$key}->{short} if $options->{$key}->{short};

                given($options->{$key}->{type}){
                        when ("string")        {$pushkey .="=s";}
                        when ("withno")        {$pushkey .="!";}
                        when ("manystring")    {$pushkey .="=s@";}
                        when ("optmanystring") {$pushkey .=":s@";}
                        when ("keyvalue")      {$pushkey .="=s%";}
                }
                push @opt_spec, [$pushkey, $options->{$key}->{text}];
        }
        return (
                @opt_spec
               );
}


# sub usage_desc
# {
#         "artemis-testruns updatehost --=s [ --queue=s@ --active=s --verbose ]*";
# }

sub validate_args
{
        my ($self, $opt, $args) = @_;

        say "Missing argument --id"     unless  $opt->{id};
        
        $opt->{active} = 1 if @$args and (grep {$_ eq '--active'} @$args);   # allow --active, even though it's not official

        my $host = model('TestrunDB')->resultset('Host')->find($opt->{id});
        if (not $host) {
                say STDERR "No host with id ",$opt->{id};
                die $self->usage->text;
        }

        if ($opt->{addqueue}) {
                foreach my $queue(@{$opt->{addqueue}}) {
                        my $queue_rs = model('TestrunDB')->resultset('Queue')->search({name => $queue});
                        if (not $queue_rs->count) {
                                say STDERR "No such queue: $queue";
                                my @queue_names = map {$_->name} model('TestrunDB')->resultset('Queue')->all;
                                say STDERR "Existing queues: ",join ", ",@queue_names;
                                die $self->usage->text;
                        }
                }
        }

        return 1 if $opt->{id};
        die $self->usage->text;
}

sub add_queues
{
        my ($self, $host, $queues) = @_;
 QUEUE:
        foreach my $queue (@$queues) {
                my $queue_rs   = model('TestrunDB')->resultset('Queue')->search({name => $queue});
                if (not $queue_rs->count) {
                        warn qq(Did not find queue "$queue" - ignoring);
                        next QUEUE;
                }
                my $queue_host = model('TestrunDB')->resultset('QueueHost')->new({
                                                                                  host_id  => $host->id,
                                                                                  queue_id => $queue_rs->first->id,
                                                                                 });
                $queue_host->insert();
        }
}

sub del_queues
{
        my ($self, $host, $queues) = @_;
 QUEUE:
        foreach my $queue (@$queues) {
                if ($queue eq '') {
                        my @queue_hosts = model('TestrunDB')->resultset('QueueHost')->search({host_id => $host->id});
                        foreach my $queue_host (@queue_hosts) {
                                $queue_host->delete();
                        }
                        return;
                }
                my $queue = model('TestrunDB')->resultset('Queue')->search({name => $queue})->first;
                if (not $queue) {
                        warn "No such queue $queue - ignoring";
                        next QUEUE;
                }
                my @queue_hosts = model('TestrunDB')->resultset('QueueHost')->search({host_id => $host->id, queue_id => $queue->id});
                foreach my $queue_host (@queue_hosts) {
                        $queue_host->delete();
                }
        }
}


sub execute 
{
        my ($self, $opt, $args) = @_;
        my $host = model('TestrunDB')->resultset('Host')->find($opt->{id});
        die "No such host: $opt->id" if not  $host;

        $host->active($opt->{active}) if defined($opt->{active});
        $host->name($opt->{name}) if $opt->{name};
        $self->del_queues($host, $opt->{delqueue}) if $opt->{delqueue};
        $self->add_queues($host, $opt->{addqueue}) if $opt->{addqueue};
        $host->update;

        my $output = sprintf("%s | %s | %s | %s", 
                             $host->id, 
                             $host->name, 
                             $host->active ? 'active' : 'deactivated', 
                             $host->free   ? 'free'   : 'in use');
        if ($host->queuehosts->count) {
                foreach my $queuehost ($host->queuehosts->all) {
                        $output.= sprintf(" | %s",$queuehost->queue->name);
                }
        } 
        say $output;
}


# perl -Ilib bin/artemis-testrun newqueue --name="xen-3.2" --priority=200

1;
