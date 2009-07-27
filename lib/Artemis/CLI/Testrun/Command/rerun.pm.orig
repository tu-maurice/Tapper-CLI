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

        #print "opt  = ", Dumper($opt);
        my $id                    = $opt->{testrun};
        my $date                  = $opt->{earliest} || DateTime->now;
        my $testrun               = model('TestrunDB')->resultset('Testrun')->find( $id );
        my $owner_user_id         = Artemis::CLI::Testrun::_get_user_id_for_login(       $opt->{owner}    ) if $opt->{owner};
        my $hardwaredb_systems_id = Artemis::CLI::Testrun::_get_systems_id_for_hostname( $opt->{hostname} ) if $opt->{hostname};
        my $testrun_new           = model('TestrunDB')->resultset('Testrun')->new
            ({
              notes                 => $opt->{notes} || $testrun->notes,
              shortname             => $testrun->shortname,
              topic_name            => $testrun->topic_name,
              starttime_earliest    => $date,
              test_program          => '',
              owner_user_id         => $owner_user_id || $testrun->owner_user_id,
              hardwaredb_systems_id => $hardwaredb_systems_id || $testrun->hardwaredb_systems_id,
             });

        $testrun_new->insert;

        my $preconditions = model('TestrunDB')->resultset('TestrunPrecondition')->search({testrun_id => $testrun->id}, { order_by => 'precondition_id' });
        while (my $precond = $preconditions->next) {
                my $precond_new = model('TestrunDB')->resultset('TestrunPrecondition')->new
                  ({
                    testrun_id => $testrun_new->id,
                    precondition_id => $precond->precondition_id,
                    succession => $precond->succession,
                   });
                $precond_new->insert;
        }

        print $opt->{verbose} ? $testrun_new->to_string : $testrun_new->id, "\n";
}


# perl -Ilib bin/artemis-testrun rerun --testrun=1234

1;
