package Artemis::Cmd::Testrun::Command::updateprecondition;

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';
use File::Slurp;

use Artemis::Model 'model';
use Artemis::Schema::TestrunDB;
use Artemis::Cmd::Testrun;
use Data::Dumper;

sub abstract {
        'Create a new precondition'
}

sub opt_spec {
        return (
                [ "verbose",                           "some more informational output"                                            ],
                [ "shortname=s",                       "TEXT; shortname", { required => 1 }                                        ],
                [ "timeout=s",                         "INT; stop trying to fullfill this precondition after timeout second",      ],
                [ "condition=s",                       "TEXT; condition description in YAML format (see Spec)"                     ],
                [ "condition_file=s",                  "STRING; filename from where to read condition, use - to read from STDIN"   ],
                [ "precondition=s@",                   "INT; assigned pre-precondition ids"                                        ],
                [ "id=s",                              "INT; the precondition id to change",                                       ],
               );
}

sub usage_desc
{
        "artemis-testrun updateprecondition --id=s [ --shortname=s | --condition=s | --condition_file=s ) ";
}

sub _allowed_opts {
        my @allowed_opts = map { $_->[0] } opt_spec();
}

sub validate_args {
        my ($self, $opt, $args) = @_;

#         print "opt  = ", Dumper($opt);
#         print "args = ", Dumper($args);
        
        my $msg = "Unknown option";
        $msg   .= ($args and $#{$args} >=1) ? 's' : '';
        $msg   .= ": ";
        say STDERR $msg, join(', ',@$args) if ($args and @$args);

        say "Missing argument --id"                   unless $opt->{id};
        #say "Missing argument --shortname"            unless $opt->{shortname};
        #say "Missing --condition or --condition_file" unless $opt->{condition} || $opt->{condition_file};
        say "Only one of --condition or --condition_file allowed." if $opt->{condition} && $opt->{condition_file};

        return 1 if $opt->{id};
        die $self->usage->text;
}

sub run {
        my ($self, $opt, $args) = @_;

        require Artemis;
        require Artemis::Config;

        #say STDERR "\n\n\n*** env: ", Artemis::Config::_getenv;
        $self->update_precondition ($opt, $args);
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

sub update_precondition
{
        my ($self, $opt, $args) = @_;

        #print "opt  = ", Dumper($opt);

        my $id                              = $opt->{id};
        my $shortname                       = $opt->{shortname}    || '';
        my $condition                       = $opt->{condition};
        my $condition_file                  = $opt->{condition_file};
        my $timeout                         = $opt->{timeout};

        $condition ||= read_condition_file($condition_file);

        exit -1 if ! Artemis::Cmd::Testrun::_yaml_ok($condition);

        my $precondition = model('TestrunDB')->resultset('Precondition')->find($id);

        if (not $precondition) {
                say "Precondition with id $id not found.";
                exit -1;

        }

        $precondition->shortname( $shortname );
        $precondition->precondition( $condition );
        $precondition->timeout( $timeout );
        $precondition->update;

        $self->assign_preconditions($opt, $args, $precondition);
        say $opt->{verbose} ? $precondition->to_string : $precondition->id;
}

sub assign_preconditions {
        my ($self, $opt, $args, $precondition) = @_;

        my @ids = @{ $opt->{precondition} || [] };

        return unless @ids;

        # delete existing assignments
        model('TestrunDB')
            ->resultset('PrePrecondition')
                ->search ({ parent_precondition_id => $precondition->id })
                    ->delete;

        # re-assign
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


# perl -Ilib bin/artemis-testrun updateprecondition --shortname=perl-5.10 --condition_file=- --timeout=100

1;
