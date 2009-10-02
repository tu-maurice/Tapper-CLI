package Artemis::CLI::Testrun::Command::listhost;

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Data::Dumper;
use Artemis::Model 'model';
use Artemis::Schema::TestrunDB;

sub abstract {
        'List hosts'
}

my $options = { "verbose"  => { text => "show all available information; without only show names", short => 'v' },
                "queue"    => { text => "list hosts bound to this queue", type=> 'manystring'},
                "active"   => { text => "list active hosts"},
                "free"     => { text => "list free hosts" },
                "name"     => { text => "find host by name, implies verbose", type => 'string'},
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


sub usage_desc {
        my $allowed_opts = join ' | ', map { '--'.$_ } _allowed_opts();
        "artemis-testruns listhost " . $allowed_opts ;
}

sub _allowed_opts {
        my @allowed_opts = map { $_->[0] } opt_spec();
}

sub _extract_bare_option_names {
        map { s/=.*//; $_} _allowed_opts();
}

sub validate_args {
        my ($self, $opt, $args) = @_;

        
        my $msg = "Unknown option";
        $msg   .= ($args and $#{$args} >=1) ? 's' : '';
        $msg   .= ": ";
        if (($args and @$args)) {
                say STDERR $msg, join(', ',@$args);
                die $self->usage->text;
        }

        $opt->{verbose} = 1 if $opt->{name};

        if ($opt->{queue}) {
                foreach my $queue(@{$opt->{queue}}) {
                        my $queue_rs = model('TestrunDB')->resultset('Queue')->search({name => $queue});
                        if (not $queue_rs->count) {
                                say STDERR "No such queue: $queue";
                                my @queue_names = map {$_->name} model('TestrunDB')->resultset('Queue')->all;
                                say STDERR "Existing queues: ",join ", ",@queue_names;
                                die $self->usage->text;
                        }
                }
        }
        return 1;
}

sub run {
        my ($self, $opt, $args) = @_;
        my %options= (order_by => 'name');
        my %search;
        $search{active} = 1 if $opt->{active};
        $search{free}   = 1 if $opt->{free};
        $search{name}   = $opt->{name}  if $opt->{name};
        if ($opt->{queue}) {
                my @queue_ids       = map {$_->id} model('TestrunDB')->resultset('Queue')->search({name => {-in => [ @{$opt->{queue}} ]}});
                $search{queue_id}   = { -in => [ @queue_ids ]};
                $options{join}      = 'queuehosts';
                $options{'+select'} = 'queuehosts.queue_id';
                $options{'+as'}     = 'queue_id';
        }
        my $hosts = model('TestrunDB')->resultset('Host')->search(\%search, \%options);
        if ($opt->{verbose}) {
                $self->print_hosts_verbose($hosts)
        } else {
                foreach my $host ($hosts->all) {
                        say sprintf("%10d | %s", $host->id, $host->name);
                }
        }
}


sub print_hosts_verbose
{
        my ($self, $hosts) = @_;
        my %max = (
                   name => 0,
                   queue => 0,
                  );
 HOST:
        foreach my $host ($hosts->all) {
                $max{name} = length($host->name) if length($host->name) > $max{name};
                next HOST if not $host->queuehosts->count;
                foreach my $queuehost ($host->queuehosts->all) {
                        $max{queue} = length($queuehost->queue->name) if length($queuehost->queue->name) > $max{queue};
                }
        }

        foreach my $host ($hosts->all) {
                my ($name_length, $queue_length) = ($max{name}, $max{queue});
                my $output = sprintf("%10d | %${name_length}s | %11s | %6s", 
                                     $host->id, 
                                     $host->name, 
                                     $host->active ? 'active' : 'deactivated', 
                                     $host->free   ? 'free'   : 'in use');
                if ($host->queuehosts->count) {
                        foreach my $queuehost ($host->queuehosts->all) {
                                $output.= sprintf(" | %${queue_length}s",$queuehost->queue->name);
                        }
                } 
                say $output;
        }
}


1;

# perl -Ilib bin/artemis-testrun list --id 16
