package Tapper::CLI::Testrun::Command::newhost;

use strict;
use warnings;

use parent 'App::Cmd::Command';

sub usage_desc
{
        "tapper-testrun newhost is DEPRECATED.\nPlease use tapper host-new";
}

sub validate_args
{
        my $self = shift;
        die $self->usage->text;
}


sub execute
{
        my $self = shift;
        die $self->usage->text;
}

1;
