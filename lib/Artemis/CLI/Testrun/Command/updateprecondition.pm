package Artemis::CLI::Testrun::Command::updateprecondition;

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';
use File::Slurp;

use Artemis::Model 'model';
use Artemis::Schema::TestrunDB;
use Artemis::CLI::Testrun;
use YAML::Syck;
use TryCatch;

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

        my $id             = $opt->{id};
        my $condition      = $opt->{condition};
        my $condition_file = $opt->{condition_file};
        my $shortname      = $opt->{shortname};


        $condition ||= read_condition_file($condition_file);
        if ($shortname) {
                my $data = Load($condition);
                $data->{shortname} = $shortname;
                $condition = Dump($data);
        }


        my $cmd = Artemis::Cmd::Precondition->new();

        try {
                $id = $cmd->update($id, $condition);
        }
          catch (Artemis::Exception::Param $except) {
                  die $except->msg();
          }

        if ($opt->{verbose}) {
                my $precondition = model('TestrunDB')->resultset('Precondition')->search({id => $id})->first;
                say $precondition->to_string;
        }  else {
                say $id;
        }
}



# perl -Ilib bin/artemis-testrun updateprecondition --shortname=perl-5.10 --condition_file=- --timeout=100

1;
