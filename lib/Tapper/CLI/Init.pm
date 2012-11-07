package Tapper::CLI::Init;

use 5.010;
use strict;
use warnings;

use Tapper::Cmd::Init;

=head1 NAME

Tapper::CLI::Init - Tapper - set up a user-specific $HOME/.tapper/

=head1 SYNOPSIS

This module is part of the Tapper::CLI framework. It is supposed to be
used together with App::Rad. All following functions expect their
arguments as $c->options->{$arg}.

    use App::Rad;
    use Tapper::CLI::Init;
    Tapper::CLI::Init::setup($c);
    App::Rad->run();

=head1 FUNCTIONS

=head2 init

Initialize a $HOME/.tapper/ with tapper.cfg and initial SQLite database.

=cut

sub init
{
        my ($c) = @_;
        $c->getopt( 'quiet|q', 'help|?', 'default|d' );

        my $use_defaults = $c->options->{default};
        if ( $c->options->{help} or not $use_defaults  ) {
                say STDERR "Usage: $0 init --default|d [ --quiet ]";
                say STDERR "";
                say STDERR "    --default    Use default values for all parameters (currently required)";
                say STDERR "    --quiet      Stay silent.";
                say STDERR "    --help       Print this help message and exit.";
                exit -1;
        }

        my %options = ( $use_defaults ?
                        (
                         db => "SQLite",
                        )
                        : (
                           db => $c->options->{db},
                          ),
                      );

        my $cmd = Tapper::Cmd::Init->new;
        $cmd->init(\%options);
        return;
}


=head2 setup

Initialize the testplan functions for tapper CLI

=cut

sub setup
{
        my ($c) = @_;
        $c->register('init', \&init, 'Initialize $HOME/.tapper/ for non-root use-cases.');
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
