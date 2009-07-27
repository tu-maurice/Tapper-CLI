package Artemis::CLI::DbDeploy::Command::init;

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Artemis::Model 'model';

use Artemis::Schema::ReportsDB;
use Artemis::Schema::TestrunDB;

use Artemis::CLI::DbDeploy;

use Data::Dumper;

sub opt_spec {
        return (
                [ "verbose", "some more informational output"       ],
                [ "db=s",    "STRING, one of: ReportsDB, TestrunDB" ],
               );
}

sub abstract {
        'Initialize a database from scratch. DANGEROUS! Think twice.'
}

sub usage_desc
{
        my $allowed_opts = join ' ', map { '--'.$_ } _allowed_opts();
        "artemis-db-deploy init --db=DBNAME  [ --verbose ]";
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

sub no_live {
        print "We currently don't do live deployment. To protect *you*!\n";
        return -1;
}

sub insert_initial_values
{
        my ($schema, $db) = @_;

        if ($db eq 'TestrunDB')
        {
                # ---------- Topic ----------

                # official topics
                my %topic_description = %Artemis::Schema::TestrunDB::Result::Topic::topic_description;

                foreach my $topic_name(keys %topic_description) {
                        my $topic = $schema->resultset('Topic')->new
                            ({ name        => $topic_name,
                               description => $topic_description{$topic_name},
                             });
                        $topic->insert;
                }
        }

        # both schema

        # ---------- User ----------

        my @users = (
                     [ 'Boris Petkov',            'bpetkov',  '' ],
                     [ 'Conny Seidel',            'cseidel',  '' ],
                     [ 'Frank Arnold',            'farnold',  '' ],
                     [ 'Frank Becker',            'fbecker',  '' ],
                     [ 'Jan Krocker',             'jkrocke2', '' ],
                     [ 'Joerg Roemer',            'jroemer',  '' ],
                     [ 'Maik Hentsche',           'mhentsc3', '' ],
                     [ 'Steffen Schwigon',        'sschwigo', '' ],
                     [ 'Steffen Schwigon@bascha', 'ss5',      '' ],
                    );

        foreach (@users) {
                say STDERR "Add ", join(", ", @$_);
                my $user = $schema->resultset('User')->new
                    ({
                      name     => $_->[0],
                      login    => $_->[1],
                      password => $_->[2],
                     });
                $user->insert;
                #say STDERR "Got ID ", $user->id;
        }
        my $user = $schema->resultset('User')->new
            ({
              id       => 0,
              name     => 'unknown',
              login    => 'unknown',
              password => 'unknown',
             });
        $user->insert;
}

sub init_db
{
        my ($self, $db) = @_;

        my $dsn  = Artemis::Config->subconfig->{database}{$db}{dsn};
        my $user = Artemis::Config->subconfig->{database}{$db}{username};
        my $pw   = Artemis::Config->subconfig->{database}{$db}{password};

        # ----- really? -----
        print "dsn = $dsn\n";
        print "Really delete all existing content and initialize from scratch (y/N)? ";
        read STDIN, my $answer, 1;
        do { print "Quit.\n"; return } unless lc $answer eq 'y';

        # ----- delete sqlite file -----
        if ($dsn =~ /dbi:SQLite:dbname/) {
                my ($tmpfname) = $dsn =~ m,dbi:SQLite:dbname=([\w./]+),i;
                unlink $tmpfname;
        }

        my $schema;
        $schema = Artemis::Schema::TestrunDB->connect ($dsn, $user, $pw) if $db eq 'TestrunDB';
        $schema = Artemis::Schema::ReportsDB->connect ($dsn, $user, $pw) if $db eq 'ReportsDB';
        $schema->deploy({ add_drop_table => 1 }); # may fail, does not provide correct order to drop tables
        insert_initial_values($schema, $db);
}

sub run
{
        my ($self, $opt, $args) = @_;

        my $db  = $opt->{db};
        my $env = $opt->{env} || 'development';

        exit usage()   unless $env =~ /^test|development|live$/;
        exit no_live() if     $env eq 'live';
        Artemis::Config::_switch_context($env);
        $self->init_db($db);
}


# perl -Ilib bin/artemis-db-deploy upgrade --db=ReportsDB

1;
