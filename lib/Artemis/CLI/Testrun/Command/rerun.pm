package Artemis::CLI::Testrun::Command::rerun;

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
use DateTime::Format::Natural;
require Artemis::Schema::TestrunDB::Result::Topic;
use Template;

use Moose;

has macropreconds => ( is => "rw" );

sub abstract {
        'Create a new testrun based on existing one'
}


sub opt_spec {
        return (
                [ "verbose",            "some more informational output"                                                                    ],
                [ "notes=s",            "TEXT; notes"                                                                                       ],
                [ "hostname=s",         "STRING; rerun test on a different machine"                                                 ],
                [ "owner=s",            "STRING, rerun test with a different user name"                                                           ],
                [ "testrun=s",          "INT, testrun to start again"                                                           ],
                [ "earliest=s",         "STRING, default=now; don't start testrun before this time (format: YYYY-MM-DD hh:mm:ss or now)"    ],
               );
}

sub usage_desc
{
        my $allowed_opts = join ' ', map { '--'.$_ } _allowed_opts();
        "artemis-testruns rerun --testrun=s [ --notes=s | --owner=s | --hostname=s | --earliest=s ]*";
}

sub _allowed_opts
{
        my @allowed_opts = map { $_->[0] } opt_spec();
}

sub convert_format_datetime_natural
{
        my ($self, $opt, $args) = @_;
        # handle natural datetimes
        if ($opt->{earliest}) {
                my $parser = DateTime::Format::Natural->new;
                my $dt = $parser->parse_datetime($opt->{earliest});
                if ($parser->success) {
                        print("%02d.%02d.%4d %02d:%02d:%02d\n", $dt->day,
                              $dt->month,
                              $dt->year,
                              $dt->hour,
                              $dt->min,
                              $dt->sec) if $opt->{verbose};
                        $opt->{earliest} = $dt;
                } else {
                        die $parser->error;
                }
        }
}

sub validate_args
{
        my ($self, $opt, $args) = @_;


        my $msg = "Unknown option";
        $msg   .= ($args and $#{$args} >=1) ? 's' : '';
        $msg   .= ": ";
        say STDERR $msg, join(', ',@$args) if ($args and @$args);

        unless ($opt->{testrun}) {
                say "Missing argument --testrun";
                die $self->usage->text;
        }
        return 1;
}

sub run
{
        my ($self, $opt, $args) = @_;

        require Artemis;

        $self->new_runtest ($opt, $args);
}


sub new_runtest
{
        my ($self, $opt, $args) = @_;

        my $id                    = $opt->{testrun};
        my $cmd = Artemis::Cmd::Testrun->new();
        my $retval = $cmd->rerun($id, $opt);
        die "Can't restart testrun $id" if not $retval;

        my $testrun = model('TestrunDB')->resultset('Testrun')->find( $retval );

        print $opt->{verbose} ? $testrun->to_string : $testrun->id, "\n";
}


# perl -Ilib bin/artemis-testrun rerun --testrun=1234

1;
