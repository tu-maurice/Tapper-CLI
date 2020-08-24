package Tapper::CLI::Testplan;
# ABSTRACT: Handle testplans

use 5.010;
use warnings;
use strict;
use Perl6::Junction qw/all/;
use English '-no_match_vars';

use JSON::XS;
use YAML::XS;


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

        require Tapper::Testplan::Reporter;
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
        $c->getopt( 'name|n=s@', 'path|p=s@', 'testrun|t=s@', 'id|i=i@','active|a','verbose|v', 'format=s', 'help|?' );

        if ( $c->options->{help} ) {
                say STDERR "Usage: $0 testplan-list [--path=path|-p=path]* [--name|-n=name]* [--testrun=id|-t=id]* [--id=number|-i=number] [--active|-a] [ --format=JSON|YAML ] [--verbose|-v]";
                say STDERR "";
                say STDERR "    --path|-p         Path name of testplans to list.";
                say STDERR "                      Only slashes(/) are allowed as separators.";
                say STDERR "                      Can be an SQL like condition (i.e. '\%name\%'). Make sure your shell does not break it.";
                say STDERR "                      Can be given multiple times";
                say STDERR "                      Will reduce number of testplans when given with --testrun or --name, can't go with --id";
                say STDERR "    --name|-n         name of testplans to list.";
                say STDERR "                      Can be an SQL like condition (i.e. '\%name\%'). Make sure your shell does not break it.";
                say STDERR "                      Can be given multiple times";
                say STDERR "                      Will reduce number of testplans when given with --testrun or --path, can't go with --id";
                say STDERR "    --testrun|-t      Show testplan containing this testrun id";
                say STDERR "                      Can be given multiple times";
                say STDERR "                      Will reduce number of testplans when given with --name or --path, can't go with --id";
                say STDERR "    --id|-i           Show testplan of given id";
                say STDERR "                      Can be given multiple times. Implies -v";
                say STDERR "                      Will override --testrun, --path and --name";
                say STDERR "    --active|-a       Only show testplan with testruns that are not finished yet.";
                say STDERR "                      Will reduce number of testplans when given with any other filter.";
                say STDERR "    --format          Give output in this format. Valid values are YAML, JSON. Case insensitive. Always verbose.";
                say STDERR "    --verbose|-v      Show testplan with id, name and associated testruns. Without only testplan id is shown.";
                say STDERR "    --help            Print this help message and exit.";
                exit -1;
        }
        my @ids;
        my $filtered;
        my $instances = model('TestrunDB')->resultset('TestplanInstance');
        my $format    = $c->options->{format};

        require Tapper::Model;
        if (@{$c->options->{id} || []}) {
                @ids = @{$c->options->{id}};
        } elsif (@{$c->options->{testrun} || []}) {
                my $testruns = Tapper::Model::model('TestrunDB')->resultset('Testrun')->search({id => $c->options->{testrun}});
                while (my $testrun = $testruns->next) {
                        push @ids, $testrun->testplan_id if $testrun->testplan_id;
                }
        } elsif ( @{$c->options->{name} || []}) {
                my $regex = join("|", map { "($_)" } @{$c->options->{name}});
                my $instances = Tapper::Model::model('TestrunDB')->resultset('TestplanInstance');
                while (my $instance = $instances->next) {
                        push @ids, $instance->id if $instance->path and $instance->path =~ /$regex/;
                }
        } else {
                my $instances = Tapper::Model::model('TestrunDB')->resultset('TestplanInstance');
                while (my $instance = $instances->next) {
                        push @ids, $instance->id;
                }
                $c->options->{verbose} = 1;
        }

        # a join would be faster and maybe cleaner
        if ($c->options->{active}) {
                my @local_ids = @ids;
                my $instances = Tapper::Model::model('TestrunDB')->resultset('TestplanInstance')->search({id => \@local_ids});
                @ids = ();
                while (my $instance = $instances->next) {
                        if ($instance->testruns and grep {$_->testrun_scheduling->status ne 'finished'} $instance->testruns->all) {
                                push @ids, $instance->id;
                        }
                }
                $instances = model('TestrunDB')->resultset('TestplanInstance')->search({id => [ @ids ]});
        }

        if ($c->options->{quiet}) {
                return join ("\n",@ids);
        }

        my $instances = Tapper::Model::model('TestrunDB')->resultset('TestplanInstance')->search({id => \@ids});
        while (my $instance = $instances->next) {
                $inst_data{$instance->id} =
                {
                 path     => $instance->path ? $instance->path : '',
                 name     => $instance->path ? $instance->path : '',
                 testruns => [ map { {id => $_->id, status => ''.$_->testrun_scheduling->status} } $instance->testruns ], # stringify enum object
                }
        }
        if ($c->options->{format}) {
                use Data::Dumper;
                given(lc($c->options->{format})) {
                        when ('yaml') { return YAML::XS::Dump(\%inst_data)}
                        when ('json') { return encode_json(\%inst_data)}
                        default       { die "unknown format: ",$c->options->{format}}
                }
        } else {
                if ($c->options->{verbose}) {
                        my @testplan_info;
                        foreach my $id (keys %inst_data) {
                                my $line = join(" - ",
                                                $id,
                                                $inst_data{$id}->{path},
                                                "testruns: ".join(", ", map{$_->{id}} @{$inst_data{$id}->{testruns}})
                                               );
                                push @testplan_info, $line;
                        }
                        return join "\n", @testplan_info;
                } else {
                        return join "\n", map { $_->id} $instances->all;
                }
        }

}

=head2 testplan_tj_send

Send all testplans reports choosen by Taskjuggler.

=cut

sub testplan_tj_send
{
        my ($c) = @_;
        if ( $c->options->{help} ) {
                say STDERR "Usage: $0 testplan-tj-send";
                say STDERR "";
                say STDERR "    --help       Print this help message and exit.";
                exit -1;
        }

        require Tapper::Testplan::Reporter;
        my $reporter = Tapper::Testplan::Reporter->new();
        $reporter->run;
        return 0;
}


=head2 testplan_tj_generate

Apply all testplans choosen by Taskjuggler.

=cut

sub testplan_tj_generate
{
        my ($c) = @_;
        if ( $c->options->{help} ) {
                say STDERR "Usage: $0 testplan-tj-generate";
                say STDERR "";
                say STDERR "    --help       Print this help message and exit.";
                exit -1;
        }
        require Tapper::Testplan::Generator;
        my $generator = Tapper::Testplan::Generator->new();
        $generator->run;
        return 0;
}

=head2 testplannew

Create new testplan instance from file.

=cut

sub testplannew
{
        my ($c) = @_;
        $c->getopt( 'include|I=s@', 'name=s', 'path=s', 'file=s', 'D=s%', 'dryrun|n', 'guide|g', 'quiet|q', 'subst_json=s','verbose|v', 'help|?' );

        my $opt = $c->options;

        if ( $opt->{help} or not $opt->{file}) {
                say STDERR "Usage: $0 testplan-new --file=s  [ -dry-run|n ] [ -v ] [ -Dkey=value ] [ --path=s ] [ --name=s ] [ --include=s ]*";
                say STDERR "";
                say STDERR "    -D           Define a key=value pair used for macro expansion";
                say STDERR "    --dryrun     Just print evaluated testplan without submit to DB";
                say STDERR "    --file       Use (macro) testplan file";
                say STDERR "    --guide      Just print self-documentation";
                say STDERR "    --include    Add include directory (multiple allowed)";
                say STDERR "    --name       Provide a name for this testplan instance";
                say STDERR "    --path       Put this path into db instead of file path";
                say STDERR "    --subst_json File name that contains macro expansion values in JSON formaxt";
                say STDERR "    --verbose    Show more progress output.";
                say STDERR "    --quiet      Only show testplan ids, suppress path, name and testrun ids.";
                say STDERR "    --help       Print this help message and exit.";
                exit -1;
        }

        die "Testplan file needed\n" if not $opt->{file};
        die "Testplan file @{[ $opt->{file} ]} does not exist"  if not -e $opt->{file};
        die "Testplan file @{[ $opt->{file} ]} is not readable" if not -r $opt->{file};

        require Tapper::Cmd::Testplan;
        if ($opt->{subst_json}) {
                use File::Slurp;
                my $data = File::Slurp::read_file($opt->{subst_json});
                $opt->{substitutes} = JSON::XS::decode_json($data);
        } else {
                        $opt->{substitutes} = $opt->{D};
        }
        my $cmd = Tapper::Cmd::Testplan->new;
        if ($opt->{guide}) {
                return $cmd->guide($opt->{file}, $opt->{substitutes}, $opt->{include});
        }
        if ($opt->{dryrun}) {
                return  $cmd->apply_macro($opt->{file}, $opt->{substitutes}, $opt->{include});
        }
        return $cmd->testplannew($opt);
}


=head2 setup

Initialize the testplan functions for tapper CLI

=cut

sub setup
{
        my ($c) = @_;
        $c->register('testplan-send', \&testplansend, 'Send choosen testplan reports');
        $c->register('testplan-list', \&testplanlist, 'List testplans matching a given pattern');
        $c->register('testplan-tj-send', \&testplan_tj_send, 'Send all testplan reports that are due according to taskjuggler plan');
        $c->register('testplan-tj-generate', \&testplan_tj_generate, 'Apply all testplans that are due according to taskjuggler plan');
        $c->register('testplan-new', \&testplannew, 'Create new testplan instance from file');
        if ($c->can('group_commands')) {
                $c->group_commands('Testplan commands', 'testplan-send', 'testplan-list', 'testplan-tj-send', 'testplan-tj-generate', 'testplan-new');
        }
        return;
}

1; # End of Tapper::CLI
