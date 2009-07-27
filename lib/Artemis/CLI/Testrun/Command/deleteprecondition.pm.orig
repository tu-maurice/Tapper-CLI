package Artemis::Cmd::Testrun::Command::deleteprecondition;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Data::Dumper;
use Artemis::Model 'model';
use Artemis::Schema::TestrunDB;

sub abstract {
        'Delete a precondition'
}

sub opt_spec {
        return (
                [ "verbose",  "some more informational output" ],
                [ "really",   "really execute the command"     ],
                [ "id=s@",    "delete particular precondition",    ],
               );
}

sub usage_desc {
        my $allowed_opts = join ' | ', map { '--'.$_ } _allowed_opts();
        "artemis-testruns deleteprecondition [ " . $allowed_opts ." ]";
}

sub _allowed_opts {
        my @allowed_opts = map { $_->[0] } opt_spec();
}

sub _extract_bare_option_names {
        map { s/=.*//; $_} _allowed_opts();
}

sub validate_args {
        my ($self, $opt, $args) = @_;

        
        my $msg = "Unknown option";
        $msg   .= ($args and $#{$args} >=1) ? 's' : '';
        $msg   .= ": ";
        say STDERR $msg, join(', ',@$args) if ($args and @$args);
        
        my $allowed_opts_re = join '|', _extract_bare_option_names();

        return 1 if grep /$allowed_opts_re/, keys %$opt;
        die $self->usage->text;
}

sub run {
        my ($self, $opt, $args) = @_;

        $self->$_ ($opt, $args) foreach grep /^id$/, keys %$opt;
}

sub id
{
        my ($self, $opt, $args) = @_;

        my @ids = @{ $opt->{id} };
        die "Really? Then add --really to the options.\n" unless $opt->{really};
        _get_entry_by_id($_)->delete foreach @ids;
}

# --------------------------------------------------

sub _get_entry_by_id {
        my ($id) = @_;
        model('TestrunDB')->resultset('Precondition')->find($id);
}

1;

# perl -Ilib bin/artemis-testrun deleteprecondition --id 16
