package Artemis::CLI::Testrun::Command::new;

use 5.010;

use strict;
use warnings;
no warnings 'uninitialized';

use parent 'App::Cmd::Command';

use YAML::Syck;
use Data::Dumper;
use File::Slurp 'slurp';
use Artemis::Model 'model';
use Artemis::Schema::TestrunDB;
use Artemis::Cmd::Precondition;
use Artemis::Cmd::Requested;
use Artemis::CLI::Testrun;
use DateTime::Format::Natural;
require Artemis::Schema::TestrunDB::Result::Topic;
use Template;

use Moose;

has macropreconds => ( is => "rw" );

sub abstract {
        'Create a new testrun'
}


my $options = { "verbose" => { text => "some more informational output" },
                "D"       => { text => "Define a key=value pair used in macro preconditions", type => 'keyvalue' },
                "file"    => { text => "String; use macro scenario file", type => 'string' },
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
        "artemis-testruns newscenario --file=s";
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
        if (($args and @$args)) {
                say STDERR $msg, join(', ',@$args);
                die $self->usage->text;
        }

        die "Scenario file needed\n",$self->usage->text if not $opt->{scenario};
        return 1;
}

=head2 execute

Worker function that 

=cut

sub execute 
{
        my ($self, $opt, $args) = @_;

        my $scenario = slurp($opt->{scenario});
        $scenario = $self->apply_macro($opt, $args) if $opt->{d};
        
        my $scenario_conf = Load($scenario);
        given $scenario_conf->{scenario_type} {
                when    ('interdep') {
                        $self->parse_interdep($scenario_conf->{description});
                }
                default {
                        die "Unknown scenario type ", $scenario_conf->{scenario_type};
                }
        }
          
        return 0;
}

=head2 apply_macro

Process macros and substit using Template::Toolkit.

@param hashref - hash containing options
@param hashref - hash containing arguments

@return success - yaml text with applied macros
@return error   - die with error string

=cut

sub apply_macro
{
        my ($self, $macro) = @_;

        my $D             = $opt->{d}; # options are auto-down-cased
        my $tt            = new Template();
        my $ttapplied;

        $tt->process(\$macro, $D, \$ttapplied) || die $tt->error();
        return $ttapplied;
}


sub add_host
{
        my ($self, $testrun_id, $host) = @_;
        my $cmd =  Artemis::Cmd::Requested->new();
        my $id = $cmd->add_host($testrun_id, $host);
        return $id;
}


sub add_feature
{
        my ($self, $testrun_id, $feature) = @_;
        my $cmd = Artemis::Cmd::Requested->new();
        my $id = $cmd->add_feature($testrun_id, $feature);
        return $id;
}

sub analyse_preconditions
{
        my ($self, @ids) = @_;
}


=head2 parse_interdep

Parse an interdep scenario and do everything needed to put it into the
database.

@param hash ref - config containing all relevant information

@return success - 0
@return error   - die with error text

=cut

sub parse_interdep
{
        my ($self, $conf) = @_;

        die "No valid preconditions given" if not @ids;

        my $cmd = Artemis::Cmd::Testrun->new();
        my $testrun_id = $cmd->add($testrun);
        die "Can't create new testrun because of an unknown error" if not $testrun_id;
        my $testrun_search = model('TestrunDB')->resultset('Testrun')->find($testrun_id);
        
        my $retval = $self->analyse_preconditions(@ids);
        
        $retval = $cmd->assign_preconditions($testrun_id, @ids);
        if ($retval) {
                $testrun_search->delete();     
                die $retval;
        }

        if ($opt->{requested_host}) {
                foreach my $host(@{$opt->{requested_host}}) {
                        push @ids, $self->add_host($testrun_id, $host);
                }
        }

        if ($opt->{requested_feature}) {
                foreach my $feature(@{$opt->{requested_feature}}) {
                        push @ids, $self->add_feature($testrun_id, $feature);
                }
        }
        $testrun_search->testrun_scheduling->status('schedule');
        $testrun_search->testrun_scheduling->update;  

        if ($opt->{verbose}) {
                say $testrun_search->to_string;
        } else {
                say $testrun_id;
        }
}



# perl -Ilib bin/artemis-testrun new --topic=Software --precondition=14  --owner=ss5

1;
