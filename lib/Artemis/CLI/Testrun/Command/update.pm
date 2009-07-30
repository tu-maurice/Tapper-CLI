package Artemis::CLI::Testrun::Command::update;

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Artemis::Model 'model';
use Artemis::Schema::TestrunDB;
use Artemis::CLI::Testrun;
use Data::Dumper;
use DateTime::Format::Natural;
require Artemis::Schema::TestrunDB::Result::Topic;

sub abstract {
        'Create a new testrun'
}

sub opt_spec {
        return (
                [ "verbose",            "some more informational output"                                                                    ],
                [ "notes=s",            "TEXT; notes"                                                                                       ],
                [ "shortname=s",        "TEXT; shortname"                                                                                   ],
                [ "topic=s",            "STRING, default=Misc; one of: Kernel, Xen, KVM, Hardware, Distribution, Benchmark, Software, Misc" ],
                [ "hostname=s",         "INT; the hostname on which the test should be run"                                                 ],
                [ "owner=s",            "STRING, default=\$USER; user login name"                                                           ],
                [ "wait_after_tests=s", "BOOL, default=0; wait after testrun for human investigation"                                       ],
                [ "earliest=s",         "STRING, default=now; don't start testrun before this time (format: YYYY-MM-DD hh:mm:ss or now)"    ],
                [ "precondition=s@",    "assigned precondition ids"                                                                         ],
                [ "id=s",               "INT; the testrun id to change",                                                               ],
               );
}

sub usage_desc
{
        my $allowed_opts = join ' ', map { '--'.$_ } _allowed_opts();
        "artemis-testruns update --id=s [ --hostname=s | --topic=s --notes=s | --shortname=s | --owner=s | --wait_after_tests=s ]*";
}

sub _allowed_opts {
        my @allowed_opts = map { $_->[0] } opt_spec();
}

sub convert_format_datetime_natural
{
        my ($self, $opt, $args) = @_;

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

sub validate_args {
        my ($self, $opt, $args) = @_;

        #         print "opt  = ", Dumper($opt);
        #         print "args = ", Dumper($args);


        my $msg = "Unknown option";
        $msg   .= ($args and $#{$args} >=1) ? 's' : '';
        $msg   .= ": ";
        say STDERR $msg, join(', ',@$args) if ($args and @$args);


        say "Missing argument --id"                   unless $opt->{id};

        # -- topic constraints --
        my $topic    = $opt->{topic} || '';
        my $topic_re = '('.join('|', keys %Artemis::Schema::TestrunDB::Result::Topic::topic_description).')';
        my $topic_ok = (!$topic || ($topic =~ /^$topic_re$/)) ? 1 : 0;
        print "Topic must match $topic_re.\n\n" unless $topic_ok;

        $self->convert_format_datetime_natural;

        return 1 if $opt->{id} && $topic_ok;
        die $self->usage->text;
}

sub run {
        my ($self, $opt, $args) = @_;

        require Artemis;

        $self->update_runtest ($opt, $args);
}

sub update_runtest
{
        my ($self, $opt, $args) = @_;

        my $cmd = Artemis::Cmd::Testrun->new();
        # args are already validated at this point, we can be sure that opt->{id} exists
        my $testrun_id = $cmd->update($opt->{id}, $opt);
        die "Can't update testrun" if not $testrun_id;

        # (XXX) descide, how to delete preconditions from a testrun
        $cmd->assign_preconditions($testrun_id, @{$opt->{precondition}}) if $opt->{precondition} and @{$opt->{precondition}};

        if ($opt->{verbose}) {
                my $testrun_search = model('TestrunDB')->resultset('Testrun')->search({id => $testrun_id});
                say $testrun_search->to_string;
        } else {
                say $testrun_id;
        }
}


# perl -Ilib bin/artemis-testrun update --id=12 --topic=Software  --hostname=iring

1;
