package Artemis::Cmd::DbDeploy::Command::makeschemadiffs;

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Artemis::Model 'model';
use Artemis::Schema::ReportsDB;
use Artemis::Schema::TestrunDB;
use Artemis::Cmd::DbDeploy;
use Artemis::Config;
use Data::Dumper;

sub opt_spec {
        return (
                [ "verbose",        "some more informational output"       ],
                [ "db=s",           "STRING, one of: ReportsDB, TestrunDB" ],
                [ "env=s",          "STRING, default=development; one of: live, development, test" ],
                [ "fromversion=s",  "STRING, the version against we make the diff" ],
                [ "upgradedir=s", "STRING, directory here upgradefiles are stored" ],
               );
}

sub abstract {
        'Save schema diff files for later upgrade'
}

sub usage_desc
{
        my $allowed_opts = join ' ', map { '--'.$_ } _allowed_opts();
        "artemis-db-deploy makeschemadiffs --db=DBNAME  [ --verbose | --env=s ]*";
}

sub _allowed_opts {
        my @allowed_opts = map { $_->[0] } opt_spec();
}

sub validate_args {
        my ($self, $opt, $args) = @_;

        #         print "opt  = ", Dumper($opt);
        #         print "args = ", Dumper($args);

        my $ok = 1;
        if (not $opt->{db})
        {
                say "Missing argument --db\n";
                $ok = 0;
        }
        elsif (not $opt->{db} =~ /^ReportsDB|TestrunDB$/)
        {
                say "Wrong DB name '".$opt->{db}."' (must be ReportsDB or TestrunDB)";
                $ok = 0;
        }
        if (not $opt->{fromversion})
        {
                say "Missing argument --fromversion\n";
                $ok = 0;
        }

        return $ok if $ok;
        die $self->usage->text;
}

sub run
{
        my ($self, $opt, $args) = @_;

        local $DBIx::Class::Schema::Versioned::DBICV_DEBUG = 1;

        Artemis::Config::_switch_context($opt->{env});

        my $db          = $opt->{db};
        my $fromversion = $opt->{fromversion};
        my $upgradedir  = $opt->{upgradedir};
        model($db)->upgrade_directory($upgradedir) if $upgradedir;
        model($db)->create_ddl_dir([qw/MySQL SQLite/],
                                   undef,
                                   ($upgradedir || model($db)->upgrade_directory),
                                   $fromversion
                                  );
}


# perl -Ilib bin/artemis-db-deploy makeschemadiffs --db=ReportsDB
# perl -Ilib bin/artemis-db-deploy makeschemadiffs --upgradedir=$HOME/local/projects/Artemis/src/Artemis-Schema/upgrades/ --db=ReportsDB --fromversion=2.010009

1;
