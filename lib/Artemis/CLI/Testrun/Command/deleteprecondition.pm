package Artemis::CLI::Testrun::Command::deleteprecondition;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Data::Dumper;
use Artemis::Model 'model';
use Artemis::Schema::TestrunDB;
use Artemis::Cmd::Precondition;



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
        die "Really? Then add --really to the options.\n" unless $opt->{really};

        return 1 if grep /$allowed_opts_re/, keys %$opt;
        die $self->usage->text;
}

sub run {
        my ($self, $opt, $args) = @_;
        my $cmd = Artemis::Cmd::Precondition->new();
        foreach my $id (@{$opt->{id}}){
                $cmd->del($id);
        }

}

1;

# perl -Ilib bin/artemis-testrun deleteprecondition --id 16
