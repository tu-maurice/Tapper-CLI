package Artemis::CLI::Testrun::Command::newprecondition;

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';
use File::Slurp;

use Artemis::Model 'model';
use Artemis::Schema::TestrunDB;
use Artemis::CLI::Testrun;
use Data::Dumper;
use YAML::Syck;

sub abstract {
        'Create a new precondition'
}

sub opt_spec {
        return (
                [ "verbose",          "some more informational output"                                            ],
                [ "timeout=s",        "INT; stop trying to fullfill this precondition after timeout second",      ],
                [ "condition=s",      "TEXT; condition description in YAML format (see Spec)"                     ],
                [ "condition_file=s", "STRING; filename from where to read condition, use - to read from STDIN"   ],
                [ "shortname=s",      "TEXT; shortname that overrides the one in the yaml"                        ],
                [ "precondition=s@",  "INT; assigned pre-precondition ids"                                        ],
               );
}

sub usage_desc
{
        "artemis-testrun newprecondition ( --condition=s | --condition_file=s ) [ --shortname=s ] [ --timeout=n ] [ --precondition=n ]* ";
}

sub _allowed_opts
{
        my @allowed_opts = map { $_->[0] } opt_spec();
}

sub validate_args
{
        my ($self, $opt, $args) = @_;

        
        my $msg = "Unknown option";
        $msg   .= ($args and $#{$args} >=1) ? 's' : '';
        $msg   .= ": ";
        say STDERR $msg, join(', ',@$args) if ($args and @$args);
        

        my $precond_ok = 1;
        if (not $opt->{condition} || $opt->{condition_file}) {
                say "Missing --condition or --condition_file";
                $precond_ok = 0;
        }
        if ($opt->{condition} && $opt->{condition_file}) {
                say "Only one of --condition or --condition_file allowed.";
                $precond_ok = 0;
        }

        return 1 if $precond_ok;
        die $self->usage->text;
}

sub run
{
        my ($self, $opt, $args) = @_;

        require Artemis;
        require Artemis::Config;

        #say STDERR "\n\n\n*** env: ", Artemis::Config::_getenv;
        $self->new_precondition ($opt, $args);
}

sub read_condition_file
{
        my ($condition_file) = @_;

        my $condition;

        # read from file or STDIN if filename == '-'
        if ($condition_file) {
                if ($condition_file eq '-') {
                        $condition = read_file (\*STDIN);
                } else {
                        $condition = read_file ($condition_file);
                }
        }
        return $condition;
}

sub new_precondition
{
        my ($self, $opt, $args) = @_;

        my $condition                       = $opt->{condition};
        my $condition_file                  = $opt->{condition_file};
        my $timeout                         = $opt->{timeout};

        $condition ||= read_condition_file($condition_file);
        $condition .= "\n" unless $condition =~ /\n$/;

        exit -1 if ! Artemis::CLI::Testrun::_yaml_ok($condition);

        my $precond_data = Load($condition);

        my $shortname    = $opt->{shortname} || $precond_data->{shortname} || '';

        my $precondition = model('TestrunDB')->resultset('Precondition')->new
            ({
              shortname    => $shortname,
              precondition => $condition,
              timeout      => $timeout,
             });
        $precondition->insert;
        $self->assign_preconditions($opt, $args, $precondition);
        print $opt->{verbose} ? $precondition->to_string : $precondition->id, "\n";
}

sub assign_preconditions {
        my ($self, $opt, $args, $precondition) = @_;

        my @ids = @{ $opt->{precondition} || [] };

        my $succession = 1;
        foreach (@ids) {
                my $pre_precondition = model('TestrunDB')->resultset('PrePrecondition')->new
                    ({
                      parent_precondition_id => $precondition->id,
                      child_precondition_id  => $_,
                      succession             => $succession,
                     });
                $pre_precondition->insert;
                $succession++
        }
}


# perl -Ilib bin/artemis-testrun newprecondition --condition_file=- --timeout=100

1;
