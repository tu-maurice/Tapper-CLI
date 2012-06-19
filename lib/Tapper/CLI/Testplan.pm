package Tapper::CLI::Testplan;

use 5.010;
use warnings;
use strict;

use Tapper::Testplan::Reporter;

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



=head2 setup

Initialize the testplan functions for tapper CLI

=cut

sub setup
{
        my ($c) = @_;
        $c->register('testplan-send', \&testplansend, 'Send testplan reports');
        if ($c->can('group_commands')) {
                $c->group_commands('Testplan commands', 'testplan-send');
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
