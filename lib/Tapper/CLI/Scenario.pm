package Tapper::CLI::Scenario;

use 5.010;
use warnings;
use strict;

use Tapper::Cmd::Scenario;
use Tapper::CLI::Utils qw/apply_macro gen_self_docu/;
use Tapper::Model 'model';

=head1 NAME

Tapper::CLI::Scenario - Tapper - scenario related commands for the tapper CLI

=head1 SYNOPSIS

This module is part of the Tapper::CLI framework. It is supposed to be
used together with App::Rad. All following functions expect their
arguments as $c->options->{$arg}.

    use App::Rad;
    use Tapper::CLI::Scenario;
    Tapper::CLI::Scenario::setup($c);
    App::Rad->run();

=head1 FUNCTIONS

=cut


=head2 scenario_new

Create a new scenario.

=cut

sub scenario_new
{
        my ($c) = @_;
        $c->getopt(  'file=s', 'D=s%', 'dryrun|n', 'guide|g', 'quiet|q', 'verbose|v', 'include|i=s@','help|?' );

        my $opt = $c->options;

        if ( $c->options->{help} or not $c->options->{file}) {
                say STDERR "Scenario file needed\n" if not $c->options->{file};
                say STDERR "Usage: $0 scenario-new --file|-f=s  [ -dry-run|-n ] [ --guide|-g ] [ -Dkey=value ]* [ --include|-i=s ]* [ --quit|-q ] [ --verbose|-v ]";
                say STDERR "";
                say STDERR "    -D            Define a key=value pair used for macro expansion";
                say STDERR "    -n|-dryrun    Just print evaluated scenario without submit to DB";
                say STDERR "    -f|--file     Use (macro) scenario file";
                say STDERR "    -g|--guide    Just print self-documentation";
                say STDERR "    -i|--include  Add an include directory. Can be given multiple times";
                say STDERR "    -v|--verbose  Print testun ids to STDERR, scenario id to STDOUT.";
                say STDERR "    -q|--quiet    Silence on success, error message on error.";
                say STDERR "    -?|--help     Print this help message and exit.";
                exit -1;
        }

        my $scenario_text = apply_macro($c->options->{file},
                                        $c->options->{D} || {},
                                        $c->options->{include});
        if ($c->options->{guide}) {
                say STDERR gen_self_docu($scenario_text);
                return;
        }

        if ($c->options->{dryrun}) {
                say STDERR $scenario_text;
                return;
        }
        my $cmd = Tapper::Cmd::Scenario->new();
        $DB::single=1;
        my @values = YAML::Syck::Load($scenario_text);
        my @scenario_ids = $cmd->add(\@values);
        if ($c->options->{quite}) {
                return;
        } elsif ($c->options->{verbose}) {
                foreach my $scenario_id (@scenario_ids) {
                        my $scenario_res = model('TestrunDB')->resultset('Scenario')->find($scenario_id);
                        print STDERR "Associated testruns: ";
                        say STDERR join ", ", map {$_->testrun->id} $scenario_res->scenario_elements->all;
                        say STDERR "Scenario ID: $scenario_id\n";
                }
                return;
        } else {
                return join "\n",@scenario_ids;
        }
}


=head2 setup

Initialize the scenario functions for tapper CLI

=cut

sub setup
{
        my ($c) = @_;
        $c->register('scenario-new', \&scenario_new,    'Create a new scenario ');
        $c->register('scenario-add', \&scenario_new,    'Alias for scenario-new');
        if ($c->can('group_commands')) {
                $c->group_commands('Scenario commands', 'scenario-new' );
        }
        return;
}

1; # End of Tapper::CLI
