package Artemis::Cmd::Testrun::Command::list;

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Data::Dumper;
use Artemis::Model 'model';
use Artemis::Schema::TestrunDB;

sub abstract {
        'List testruns'
}

my $options = { "verbose"  => { text => "some more informational output" },
                "colnames" => { text => "print out column names" },
                "all"      => { text => "list all testruns", needed => 1 },
                "finished" => { text => "list finished testruns", needed => 1 },
                "running"  => { text => "list running testruns", needed => 1 },
                "queued"   => { text => "list queued testruns", needed => 1 },
                "due"      => { text => "list due testruns", needed => 1 },
                "id"       => { text => "list particular testruns", type => 'int', needed => 1 },

              };
                

sub opt_spec {
        my @opt_spec;
        foreach my $key (keys %$options) {
                my $pushkey = defined $options->{$key}->{type} ? $key."=s@" : $key;
                push @opt_spec, [$pushkey, $options->{$key}->{text}];
        }
        return (
                @opt_spec
               );
}

sub usage_desc {
        my $allowed_opts = join ' | ', map { '--'.$_ } _allowed_opts();
        "artemis-testruns listprecondition [ " . $allowed_opts ." ]";
}

sub _allowed_opts {
        my @allowed_opts = map { $_->[0] } opt_spec();
}

sub _extract_bare_option_names {
        map { s/=.*//; $_} _allowed_opts();
}

sub validate_args {
        my ($self, $opt, $args) = @_;
        my @allowed_opts;
        foreach my $key (keys %$options) {
                push @allowed_opts, $key if  $options->{$key}->{needed};
        }

        
        my $msg = "Unknown option";
        $msg   .= ($args and $#{$args} >=1) ? 's' : '';
        $msg   .= ": ";
        say STDERR $msg, join(', ',@$args) if ($args and @$args);
        
        
        my $allowed_opts_re = join '|', @allowed_opts;

        return 1 if grep /$allowed_opts_re/, keys %$opt;
        die $self->usage->text;
}

sub run {
        my ($self, $opt, $args) = @_;

        $self->$_ ($opt, $args) foreach grep /^all|finished|running|queued|due|id$/, keys %$opt;
}

sub print_colnames
{
        my ($self, $opt, $args) = @_;

        return unless $opt->{colnames};

        my $columns = model('TestrunDB')->resultset('Testrun')->result_source->{_ordered_columns};
        print join( $Artemis::Schema::TestrunDB::DELIM, @$columns, '' ), "\n";
}

sub all
{
        my ($self, $opt, $args) = @_;

        print "All testruns:\n" if $opt->{verbose};
        $self->print_colnames($opt, $args);

        my $testruns = model('TestrunDB')->resultset('Testrun')->all_testruns->search({}, { order_by => 'id' });
        while (my $testrun = $testruns->next) {
                print $testrun->to_string."\n";
        }
}

sub queued
{
        my ($self, $opt, $args) = @_;

        print "Queued testruns:\n" if $opt->{verbose};
        $self->print_colnames($opt, $args);

        my $testruns = model('TestrunDB')->resultset('Testrun')->queued_testruns->search({}, { order_by => 'id' });
        while (my $testrun = $testruns->next) {
                print $testrun->to_string."\n";
        }
}

sub due
{
        my ($self, $opt, $args) = @_;

        print "Due testruns:\n" if $opt->{verbose};
        $self->print_colnames($opt, $args);

        my $testruns = model('TestrunDB')->resultset('Testrun')->due_testruns->search({}, { order_by => 'id' });
        while (my $testrun = $testruns->next) {
                print $testrun->to_string."\n";
        }
}

sub running
{
        my ($self, $opt, $args) = @_;

        print "Running testruns:\n" if $opt->{verbose};
        $self->print_colnames($opt, $args);

        my $testruns = model('TestrunDB')->resultset('Testrun')->running_testruns->search({}, { order_by => 'id' });
        while (my $testrun = $testruns->next) {
                print $testrun->to_string."\n";
        }
}

sub finished
{
        my ($self, $opt, $args) = @_;

        print "Finished testruns:\n" if $opt->{verbose};
        $self->print_colnames($opt, $args);

        my $testruns = model('TestrunDB')->resultset('Testrun')->finished_testruns->search({}, { order_by => 'id' });
        while (my $testrun = $testruns->next) {
                print $testrun->to_string."\n";
        }
}

sub id
{
        my ($self, $opt, $args) = @_;

        my @ids = @{ $opt->{id} };

        $self->print_colnames($opt, $args);
        foreach (@ids) {
                my $entry = _get_entry_by_id($_);
                say $entry ? $entry->to_string : "No such id $_";
        }
}

# --------------------------------------------------

sub _get_entry_by_id {
        my ($id) = @_;
        model('TestrunDB')->resultset('Testrun')->find($id);
}

1;

# perl -Ilib bin/artemis-testrun list --id 16
