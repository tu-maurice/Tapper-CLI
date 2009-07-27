package Artemis::Cmd::Testrun::Command::listprecondition;

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Data::Dumper;
use Artemis::Model 'model';
use Artemis::Schema::TestrunDB;

sub abstract {
        'List preconditions'
}

my $options = { "verbose"     => { text => "some more informational output" },
                "id_only"     => { text => "only show ids of matching preconditions" },
                "nonewlines"  => { text => "escape newlines in values to avoid multilines" },
                "quotevalues" => { text => "put quotes around the values" },
                "colnames"    => { text => "print out column names" },
                "all"         => { text => "list all preconditions", needed => 1 },
                "lonely"      => { text => "neither a preprecondition nor assigned to a testrun", needed => 1 },
                "primary"     => { text => "assigned to one or more testruns", needed => 1 },
                "testrun"     => { text => "assigned to given testrun id", needed => 1, type => 'int' },
                "pre"         => { text => "only prepreconditions not assigned to a testrun", needed => 1 },
                "id"          => { text => "list particular precondition", needed => 1, type => 'int'  },
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

        $self->$_ ($opt, $args) foreach grep /^(all|lonely|primary|pre|id|testrun)$/, keys %$opt;
}

=head2 testrun

Return all preconditions for a given testrun id.

=cut

sub testrun
{ 
        my ($self, $opt, $args) = @_;
        print "All preconditions:\n" if $opt->{verbose};
        print "| Id |\n------\n" if $opt->{id_only};
        my @ids = @{ $opt->{testrun} };
        $self->print_colnames($opt, $args);
        
        my $preconditions = model('TestrunDB')->resultset('TestrunPrecondition')->search({testrun_id => @ids}, { order_by => 'precondition_id' });
        while (my $precond = $preconditions->next) {
                if ($opt->{id_only}) {
                        print "| ",join (", ",$precond->id)," |\n";
                } else {
                        my $precond_yaml = model('TestrunDB')->resultset('Precondition')->search({id => $precond->precondition_id});
                        foreach my $yaml($precond_yaml->next) {
                                print $yaml->to_string()."\n";
                        }
                }
        }
        

}

sub print_colnames
{
        my ($self, $opt, $args) = @_;

        return unless $opt->{colnames};

        my $columns = model('TestrunDB')->resultset('Precondition')->result_source->{_ordered_columns};
        print join( $Artemis::Schema::TestrunDB::DELIM, @$columns, '' ), "\n";
}

sub all
{
        my ($self, $opt, $args) = @_;

        print "All preconditions:\n" if $opt->{verbose};
        print "| Id |\n------\n" if $opt->{id_only};
        $self->print_colnames($opt, $args);

        my $preconditions = model('TestrunDB')->resultset('Precondition')->all_preconditions->search({}, { order_by => 'id' });
        while (my $precond = $preconditions->next) {
                if ($opt->{id_only}) {
                        print "| ",$precond->id," |\n";
                } else {
                        print $precond->to_string($opt)."\n";
                }
        }
}


sub lonely
{
        my ($self, $opt, $args) = @_;

        print "Preconditions referenced by neither precondition nor testrun:\n" if $opt->{verbose};
        $self->print_colnames($opt, $args);

        print "Implement me. Now!\n";
        return;

        my $preconditions = model('TestrunDB')->resultset('Precondition')->lonely_preconditions->search({}, { order_by => 'id' });
        while (my $precond = $preconditions->next) {
                print $precond->to_string($opt)."\n";
        }
}

sub primary
{
        my ($self, $opt, $args) = @_;

        print "Preconditions directly referenced by a testrun:\n" if $opt->{verbose};
        $self->print_colnames($opt, $args);

        print "Implement me. Now!\n";
        return;

        my $preconditions = model('TestrunDB')->resultset('Precondition')->primary_preconditions->search({}, { order_by => 'id' });
        while (my $precond = $preconditions->next) {
                print $precond->to_string($opt)."\n";
        }
}

sub pre
{
        my ($self, $opt, $args) = @_;

        print "Preconditions directly referenced by another precondition:\n" if $opt->{verbose};
        $self->print_colnames($opt, $args);

        print "Implement me. Now!\n";
        return;

        my $preconditions = model('TestrunDB')->resultset('Precondition')->pre_preconditions->search({}, { order_by => 'id' });
        while (my $precond = $preconditions->next) {
                print $precond->to_string($opt)."\n";
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
        model('TestrunDB')->resultset('Precondition')->find($id);
}

1;

# perl -Ilib bin/artemis-testrun listprecondition --all --colnames
# perl -Ilib bin/artemis-testrun listprecondition --all --colnames --nonewlines 
# perl -Ilib bin/artemis-testrun listprecondition --all --colnames --nonewlines --quotevalues
