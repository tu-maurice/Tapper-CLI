package Artemis::CLI::Testrun::Command::new;

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
        'Create a new testrun'
}


my $options = { "verbose"          => { text => "some more informational output" },
                "notes"            => { text => "TEXT; notes", type => 'string' },
                "shortname"        => { text => "TEXT; shortname", type => 'string' },
                "topic"            => { text => "STRING, default=Misc; one of: Kernel, Xen, KVM, Hardware, Distribution, Benchmark, Software, Misc", type => 'string' },
                "hostname"         => { text => "INT; the hostname on which the test should be run", type => 'string' },
                "owner"            => { text => "STRING, default=\$USER; user login name", type => 'string' },
                "wait_after_tests" => { text => "BOOL, default=0; wait after testrun for human investigation", type => 'string' },
                "earliest"         => { text => "STRING, default=now; don't start testrun before this time (format: YYYY-MM-DD hh:mm:ss or now)", type => 'string' },
                "precondition"     => { text => "assigned precondition ids", needed => 1, type => 'manystring'  },
                "macroprecond"     => { text => "STRING, use this macro precondition file", needed => 1 , type => 'string' },
                "D"                => { text => "Define a key=value pair used in macro preconditions", type => 'keyvalue' },
                };

sub opt_spec {
        my @opt_spec;
        foreach my $key (keys %$options) {
                my $pushkey;
                given($options->{$key}->{type}){
                        when ("string")     {$pushkey = $key ."=s";}
                        when ("manystring") {$pushkey = $key ."=s@";}
                        when ("keyvalue")   {$pushkey = $key ."=s%";}
                        default             {$pushkey = $key; }
                }
                push @opt_spec, [$pushkey, $options->{$key}->{text}];
        }
        return (
                @opt_spec
               );
}


sub usage_desc
{
        my $allowed_opts = join ' ', map { '--'.$_ } _allowed_opts();
        "artemis-testruns new --hostname=s [ --topic=s --notes=s | --shortname=s | --owner=s | --wait_after_tests=s | --macroprecond=s | -Dkey=val ]*";
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

        #         print "opt  = ", Dumper($opt);
        #         print "args = ", Dumper($args);

        say "Missing argument --hostname"                   unless  $opt->{hostname};

        # -- topic constraints --
        my $topic    = $opt->{topic} || '';
        my $topic_re = '('.join('|', keys %Artemis::Schema::TestrunDB::Result::Topic::topic_description).')';
        my $topic_ok = (!$topic || ($topic =~ /^$topic_re$/)) ? 1 : 0;
        say STDERR "Topic must match $topic_re." unless $topic_ok;
        
        my $msg = "Unknown option";
        $msg   .= ($args and $#{$args} >=1) ? 's' : '';
        $msg   .= ": ";
        say STDERR $msg, join(', ',@$args) if ($args and @$args);
        

        my @needed_opts;
        my $precondition_ok;
        foreach my $key (keys %$options) {
                push @needed_opts, $key if  $options->{$key}->{needed};
        }
        
        my $needed_opts_re = join '|', @needed_opts;

        if (grep /$needed_opts_re/, keys %$opt) {
                $precondition_ok = 1;
        } else {
                say STDERR "At least one of ",join ", ",@needed_opts," is required.";
        }


        $self->convert_format_datetime_natural;

        my $macrovalues_ok = 1;
        if ($opt->{macroprecond}) {
                my @precond_lines =  slurp $opt->{macroprecond};
                my @mandatory;
                if ($precond_lines[0] =~/# (artemis[_-])?mandatory[_-]fields:(.+)/) {
                        @mandatory = split (" ", $2);
                        shift @precond_lines;
                }
                
                foreach my $field(@mandatory)
                {
                        if (not $opt->{d}{$field}) {
                                say STDERR "Expected macro field '$field' missing.";
                                $macrovalues_ok = 0;
                        }
                }
                $self->{macropreconds} = join '',@precond_lines;
        }

        return 1 if $opt->{hostname} and $topic_ok and $precondition_ok and $macrovalues_ok;

        die $self->usage->text;
}

sub run
{
        my ($self, $opt, $args) = @_;

        require Artemis;

        $self->new_runtest ($opt, $args);
}

=head2 create_macro_preconditions

Process a macroprecondition. This includes substitions using
Template::Toolkit, separating the individual preconditions that are part of
the macroprecondition and putting them into the database. Parameters fit the
App::Cmd::Command API.

@param hashref - hash containing options
@param hashref - hash containing arguments

@returnlist array containing precondition ids

=cut 

sub create_macro_preconditions
{
        my ($self, $opt, $args) = @_;

        my @ids = ();

        my $D             = $opt->{d}; # options are auto-down-cased
        my $tt            = new Template ();
        my $macro         = $self->{macropreconds};
        my $ttapplied;

        $tt->process(\$macro, $D, \$ttapplied) || die $tt->error();
        exit -1 if ! Artemis::CLI::Testrun::_yaml_ok($ttapplied);
        my @precond_data = Load($ttapplied);

 CONDITION:
        foreach my $condition (@precond_data)
        {
                my $shortname    = $opt->{shortname} || $condition->{shortname} || $condition->{name} || 'macro.'.$condition->{precondition_type};
                my $precondition = model('TestrunDB')->resultset('Precondition')->new
                    ({
                      shortname    => $shortname,
                      precondition => Dump($condition),
                     });
                $precondition->insert;
                push @ids, $precondition->id;
        }
        return @ids;
}

sub new_runtest
{
        my ($self, $opt, $args) = @_;

        #print "opt  = ", Dumper($opt);

        my $notes        = $opt->{notes}        || '';
        my $shortname    = $opt->{shortname}    || '';
        my $topic_name   = $opt->{topic}        || 'Misc';
        my $date         = $opt->{earliest}     || DateTime->now;
        my $hostname     = $opt->{hostname};
        my $owner        = $opt->{owner}        || $ENV{USER};

        my $hardwaredb_systems_id = Artemis::CLI::Testrun::_get_systems_id_for_hostname( $hostname );
        my $owner_user_id         = Artemis::CLI::Testrun::_get_user_id_for_login( $owner );

        my $testrun = model('TestrunDB')->resultset('Testrun')->new
            ({
              notes                 => $notes,
              shortname             => $shortname,
              topic_name            => $topic_name,
              starttime_earliest    => $date,
              owner_user_id         => $owner_user_id,
              hardwaredb_systems_id => $hardwaredb_systems_id,
             });
        $testrun->insert;
        $self->assign_preconditions($opt, $args, $testrun);
        print $opt->{verbose} ? $testrun->to_string : $testrun->id, "\n";
}

sub assign_preconditions {
        my ($self, $opt, $args, $testrun) = @_;

        my @ids;
        if ($opt->{macroprecond})
        {
                @ids = $self->create_macro_preconditions($opt, $args);
        }
        else
        {
                @ids = @{ $opt->{precondition} || [] };
        }
        my $succession = 1;
        foreach (@ids) {
                my $testrun_precondition = model('TestrunDB')->resultset('TestrunPrecondition')->new
                    ({
                      testrun_id      => $testrun->id,
                      precondition_id => $_,
                      succession      => $succession,
                     });
                $testrun_precondition->insert;
                $succession++
        }
}


# perl -Ilib bin/artemis-testrun new --topic=Software --precondition=14  --hostname=iring --owner=ss5

1;
