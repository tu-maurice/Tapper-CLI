package Artemis::Cmd::Testrun;

use strict;
use warnings;

use parent 'App::Cmd';

use YAML::Syck;
use Artemis::Model 'model';
use Artemis::Schema::TestrunDB;
use Artemis::Schema::HardwareDB;

sub opt_spec
{
        my ( $class, $app ) = @_;

        return (
                [ 'help' => "This usage screen" ],
                $class->options($app),
               );
}

sub validate_args
{
        my ( $self, $opt, $args ) = @_;

        die $self->_usage_text if $opt->{help};
        $self->validate( $opt, $args );
}

sub _get_systems_id_for_hostname
{
        my ($name) = @_;
        return model('HardwareDB')->resultset('Systems')->search({systemname => $name, active => 1})->first->lid
}

sub _get_user_id_for_login
{
        my ($login) = @_;

        my $user = model('TestrunDB')->resultset('User')->search({ login => $login })->first;
        my $user_id = $user ? $user->id : 0;
        return $user_id;
}

sub _yaml_ok {
        my ($condition) = @_;

        my $res;
        eval {
                $res = Load($condition);
        };
        if ($@) {
                warn "Condition yaml contains errors: $@" unless $ENV{HARNESS_ACTIVE};
                return 0;
        }
        return 1;
}

1;

