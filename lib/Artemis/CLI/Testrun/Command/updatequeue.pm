package Artemis::CLI::Testrun::Command::updatequeue;

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Artemis::Model 'model';
use Artemis::CLI::Testrun;
use Artemis::Cmd::Queue;

sub abstract {
        'Update an existing queue'
}


my $options =  {
                "verbose"          => { text => "some more informational output", short => 'v' },
                "name"             => { text => "TEXT; name of the queue to be changed",    type => 'string' },
                "priority"         => { text => "INT; priority", type => 'string', short => 'p' },
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


sub usage_desc
{
        "artemis-testruns updatequeue --name=s --priority=s [ --verbose ]";
}

sub validate_args
{
        my ($self, $opt, $args) = @_;

        say "Missing argument --name"     unless  $opt->{name};
        say "Missing argument --priority, this is the only changable value" unless  $opt->{priority};

        return 1 if $opt->{name} and $opt->{priority};

        die $self->usage->text;
}

sub update_queue
{
        my ($self, $opt, $args) = @_;

        my $queue = model('TestrunDB')->resultset('Queue')->search({name => $opt->{name}})->first;
        
        my $cmd = Artemis::Cmd::Queue->new();
        my $queue_id = $cmd->update($queue->id, {priority => $opt->{priority}});
        die "Can't create new queue because of an unknown error" if not $queue_id;

        if ($opt->{verbose}) {
                $queue = model('TestrunDB')->resultset('Queue')->find($queue_id);
                say $queue->name, " | ", $queue->priority;
        } else {
                say $queue_id;
        }
}

sub run
{
        my ($self, $opt, $args) = @_;

        $self->update_queue ($opt, $args);
}


# perl -Ilib bin/artemis-testrun newqueue --name="xen-3.2" --priority=200

1;
