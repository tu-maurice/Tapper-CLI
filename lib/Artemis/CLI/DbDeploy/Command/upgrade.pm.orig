package Artemis::Cmd::DbDeploy::Command::upgrade;

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
                [ "verbose", "some more informational output"       ],
                [ "db=s",    "STRING, one of: ReportsDB, TestrunDB" ],
                [ "env=s",   "STRING, default=development; one of: live, development, test" ],
                [ "upgradedir=s", "STRING, directory where upgradefiles are stored" ],
                [ "fromversion=s","STRING" ],
                [ "toversion=s",  "STRING" ],
               );
}

# aktuelle Version und Diff erzeugen zur gewünschten vorherigen
# perl -Ilib -MArtemis::Schema::ReportsDB -e 'Artemis::Schema::ReportsDB->connect("DBI:SQLite:foo")->create_ddl_dir([qw/MySQL SQLite/], undef, "upgrades/", "2.010012") or die'

sub abstract {
        'Upgrade a database schema'
}

sub usage_desc
{
        my $allowed_opts = join ' ', map { '--'.$_ } _allowed_opts();
        "artemis-db-deploy upgrade --db=DBNAME  [ --verbose | --env=s ]";
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

        return $ok if $ok;
        die $self->usage->text;
}

sub run
{
        my ($self, $opt, $args) = @_;

        local $DBIx::Class::Schema::Versioned::DBICV_DEBUG = 1;

        Artemis::Config::_switch_context($opt->{env});

        my $db = $opt->{db};
        my $upgradedir  = $opt->{upgradedir};
        model($db)->upgrade_directory($upgradedir) if $upgradedir;
        model($db)->upgrade;
}


# perl -Ilib bin/artemis-db-deploy upgrade --db=ReportsDB

1;
