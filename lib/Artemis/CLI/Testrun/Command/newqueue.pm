package Artemis::CLI::Testrun::Command::newqueue;

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use YAML::Syck;
use Data::Dumper;
use File::Slurp 'slurp';
use Artemis::Model 'model';
use Artemis::Schema::TestrunDB;
use Artemis::CLI::Testrun;
use Artemis::Cmd::Queue;
use DateTime::Format::Natural;
require Artemis::Schema::TestrunDB::Result::Topic;
use Template;

use Moose;

has macropreconds => ( is => "rw" );

sub abstract {
        'Create a new queue'
}


my $options =  {
                "verbose"          => { text => "some more informational output" },
                "name"             => { text => "TEXT; name",    type => 'string' },
                "priority"         => { text => "INT; priority", type => 'string' },
                };

sub opt_spec {
        my @opt_spec;
        foreach my $key (keys %$options) {
                my $pushkey;
                given($options->{$key}->{type}){
                        when ("string")     {$pushkey = $key ."=s";}
                        when ("manystring") {$pushkey = $key ."=s@";}
                        when ("keyvalue")   {$pushkey = $key ."=s%";}
                        default             {$pushkey = $key; }
                }
                push @opt_spec, [$pushkey, $options->{$key}->{text}];
        }
        return (
                @opt_spec
               );
}


sub usage_desc
{
        "artemis-testruns newqueue --name=s --priority=s [ --verbose ]";
}

sub validate_args
{
        my ($self, $opt, $args) = @_;

        #         print "opt  = ", Dumper($opt);
        #         print "args = ", Dumper($args);

        say "Missing argument --name"     unless  $opt->{name};
        say "Missing argument --priority" unless  $opt->{priority};

        return 1 if $opt->{name} and $opt->{priority};

        die $self->usage->text;
}

sub new_queue
{
        my ($self, $opt, $args) = @_;

        #print "opt  = ", Dumper($opt);

        my $queue = {
                     name        => $opt->{name},
                     priority    => $opt->{priority},
                    };
        my @ids;

        my $cmd = Artemis::Cmd::Queue->new();
        my $queue_id = $cmd->add($queue);
        die "Can't create new queue because of an unknown error" if not $queue_id;

        if ($opt->{verbose}) {
                my $entry = model('TestrunDB')->resultset('Queue')->search({id => $queue_id})->first;
                say $entry->to_string;
        } else {
                say $queue_id;
        }
}

sub run
{
        my ($self, $opt, $args) = @_;

        $self->new_queue ($opt, $args);
}


# perl -Ilib bin/artemis-testrun newqueue --name="xen-3.2" --priority=200

1;
