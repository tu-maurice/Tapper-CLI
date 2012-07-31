package Tapper::CLI::Testplan;

use 5.010;
use warnings;
use strict;

use Tapper::Testplan::Reporter;
use Tapper::Model 'model';


=head1 NAME

Tapper::CLI::Testplan - Tapper - testplan related commands for the tapper CLI

=head1 SYNOPSIS

This module is part of the Tapper::CLI framework. It is supposed to be
used together with App::Rad. All following functions expect their
arguments as $c->options->{$arg}.

    use App::Rad;
    use Tapper::CLI::Testplan;
    Tapper::CLI::Testplan::setup($c);
    App::Rad->run();

=head1 FUNCTIONS

=head2 testplansend

Send testplan reports to Taskjuggler. If optional names are given only tasks
that match at least one such name are reported.

@optparam name  - full subtask path (bot dot and slash are allowed as separatot)
@optparam quiet - stay silent when testplan was sent
@optparam help  - print out help message and die

=cut

sub testplansend
{
        my ($c) = @_;
        $c->getopt( 'name|n=s@','file|f=s@','quiet|q', 'help|?' );

        if ( $c->options->{help} ) {
                say STDERR "Usage: $0 testplan-send [ --name=path ]* [ --file=filename ]  [ --quiet ]";
                say STDERR "";
                say STDERR "    --name       Path name to request only this task to be reported.";
                say STDERR "                 Slash(/) or dot(.) are allowed as separators.";
                say STDERR "                 Can be given multiple times.";
                say STDERR "                 Can be combined with --file.";
                say STDERR "    --file       File containing tasknames to be reported, one per line.";
                say STDERR "                 Slash(/) or dot(.) are allowed as separators.";
                say STDERR "                 Can be given multiple times.";
                say STDERR "                 Can be combined with --name.";
                say STDERR "    --quiet      Stay silent when testplan was sent.";
                say STDERR "    --help       Print this help message and exit.";
                exit -1;
        }

        my @names;
        if ($c->options->{name}) {
                push @names, map { tr|.|/|; { path => $_ } } @{$c->options->{name}}; ## no critic
        }
        if ($c->options->{file}) {
                foreach my $file (@{$c->options->{file}}) {
                        open my $FILE, "<", $file or die "Cannot open $file";
                        my @tasknames = map { chomp ; $_ } <$FILE>;
                        close $FILE;
                        push @names, map { tr|.|/|; { path => $_ } } @tasknames; ## no critic
                }
        }

        my $reporter = Tapper::Testplan::Reporter->new();
        $reporter->run(@names);
        return "Sending testplan finished" unless $c->options->{quiet};
        return;
}

=head2 testplanlist

List testplans matching a given pattern.

=cut

sub testplanlist
{
        my ($c) = @_;
        $c->getopt( 'name|n=s@','testrun|t=s@', 'active|a', 'quiet|q', 'help|?' );

        if ( $c->options->{help} ) {
                say STDERR "Usage: $0 testplan-list [ --name=path ]* [ --testrun=id ]*  [ --quiet ]";
                say STDERR "";
                say STDERR "    --name       Path name of testplans to list.";
                say STDERR "                 Only slashes(/) are allowed as separators.";
                say STDERR "                 Can be a regular expression. Make sure your shell does not break it.";
                say STDERR "                 Can be given multiple times";
                say STDERR "    --testrun    Show testplan containing this testrun id";
                say STDERR "                 Can be given multiple times";
                say STDERR "    --id         Show testplan of given id";
                say STDERR "                 Can be given multiple times.";
                say STDERR "    --active     Only show testplan with testruns that are not finished yet.";
                say STDERR "    --quiet      Only show testplan ids, suppress path, name and testrun ids.";
                say STDERR "    --help       Print this help message and exit.";
                exit -1;
        }
        my @ids;
        my @testplan_info;

        if (@{$c->options->{testrun} || []}) {
                my $testruns = model('TestrunDB')->resultset('Testrun')->search({id => $c->options->{testrun}});
                while (my $testrun = $testruns->next) {
                        push @ids, $testrun->testplan_id if $testrun->testplan_id;
                }
        } elsif ( @{$c->options->{name} || []}) {
                my $regex = join("|", map { "($_)" } @{$c->options->{name}});
                my $instances = model('TestrunDB')->resultset('TestplanInstance');
                while (my $instance = $instances->next) {
                        push @ids, $instance->id if $instance->path and $instance->path =~ /$regex/;
                }
        } else {
                my $instances = model('TestrunDB')->resultset('TestplanInstance');
                while (my $instance = $instances->next) {
                        push @ids, $instance->id;
                }
        }

        if ($c->options->{active}) {
                my @local_ids = @ids;
                my $instances = model('TestrunDB')->resultset('TestplanInstance')->search({id => \@local_ids});
                @ids = ();
                while (my $instance = $instances->next) {
                        if ($instance->testruns and grep {$_->testrun_scheduling->status ne 'finished'} $instance->testruns->all) {
                                push @ids, $instance->id;
                        }
                }
        }

        if ($c->options->{quiet}) {
                return join ("\n",@ids);
        }

        my $instances = model('TestrunDB')->resultset('TestplanInstance')->search({id => \@ids});
        while (my $instance = $instances->next) {
                my $line = $instance->id;
                $line   .= " - ";
                $line   .= ($instance->path ? $instance->path : '' )." - ";
                $line   .= "testruns: ";
                $line   .= join ", ", map {$_->id} $instance->testruns->all;
                push @testplan_info, $line;
        }
        return join "\n", @testplan_info;
}

=head2 setup

Initialize the testplan functions for tapper CLI

=cut

sub setup
{
        my ($c) = @_;
        $c->register('testplan-send', \&testplansend, 'Send testplan reports');
        $c->register('testplan-list', \&testplanlist, 'List testplans matching a given pattern');
        if ($c->can('group_commands')) {
                $c->group_commands('Testplan commands', 'testplan-send', 'testplan-list');
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
