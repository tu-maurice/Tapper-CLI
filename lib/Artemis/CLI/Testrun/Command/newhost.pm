package Artemis::CLI::Testrun::Command::newhost;

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Artemis::Model 'model';
use Artemis::CLI::Testrun;


sub abstract {
        'Create a new testrun'
}


my $options =  {
                "verbose"          => { text => "some more informational output" },
                "name"             => { text => "TEXT; name",    type => 'string' },
                "active"           => { text => "INT; MCP can use this host, default 0", type => 'bool' },
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
        "artemis-testruns newqueue --name=s --active=s [ --verbose ]";
}

sub validate_args
{
        my ($self, $opt, $args) = @_;

        say "Missing argument --name"     unless  $opt->{name};

        return 1 if $opt->{name};

        die $self->usage->text;
}

sub new_host
{
        my ($self, $opt, $args) = @_;


        my $host = {
                    name   => $opt->{name},
                    active => $opt->{active},
                   };

        my $newhost = model('TestrunDB')->resultset('Host')->new($host);
        $newhost->insert();
        die "Can't create new host" if not $newhost;
        say $newhost->id;
}

sub run
{
        my ($self, $opt, $args) = @_;

        $self->new_host ($opt, $args);
}


# perl -Ilib bin/artemis-testrun newqueue --name="xen-3.2" --priority=200

1;
