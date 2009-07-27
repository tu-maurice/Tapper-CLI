use Test::More tests => 18;

BEGIN {
        use Class::C3;
        use MRO::Compat;

        use_ok( 'Artemis::CLI::API::Command::upload' );
        use_ok( 'Artemis::CLI::DbDeploy' );
        use_ok( 'Artemis::CLI::Testrun::Command::delete' );
        use_ok( 'Artemis::CLI::Testrun::Command::show' );
        use_ok( 'Artemis::CLI::Testrun::Command::newprecondition' );
        use_ok( 'Artemis::CLI::Testrun::Command::deleteprecondition' );
        use_ok( 'Artemis::CLI::Testrun::Command::updateprecondition' );
        use_ok( 'Artemis::CLI::Testrun::Command::new' );
        use_ok( 'Artemis::CLI::Testrun::Command::update' );
        use_ok( 'Artemis::CLI::Testrun::Command::listprecondition' );
        use_ok( 'Artemis::CLI::Testrun::Command::list' );
        use_ok( 'Artemis::CLI::DbDeploy::Command::makeschemadiffs' );
        use_ok( 'Artemis::CLI::DbDeploy::Command::init' );
        use_ok( 'Artemis::CLI::DbDeploy::Command::upgrade' );
        use_ok( 'Artemis::CLI::DbDeploy::Command::saveschema' );
        use_ok( 'Artemis::CLI::API' );
        use_ok( 'Artemis::CLI::Testrun' );
        use_ok( 'Artemis::CLI' );
}

diag( "Testing Artemis::CLI $Artemis::CLI::VERSION, Perl $], $^X" );
