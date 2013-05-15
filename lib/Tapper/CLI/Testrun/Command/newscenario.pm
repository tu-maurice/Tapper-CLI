package Tapper::CLI::Testrun::Command::newscenario;

use 5.010;

use strict;
use warnings;
no warnings 'uninitialized';

use parent 'App::Cmd::Command';
use YAML::XS;

use Tapper::Cmd::Scenario;
use Tapper::Cmd::Testrun;
use Tapper::Cmd::Precondition;
use Tapper::Cmd::Requested;
use Tapper::Config;

sub abstract {
        'Deprecated, use tapper scenario-new';
}



sub usage_desc
{
        return abstract();
}


sub validate_args
{
        die abstract,"\n";
}

1;
