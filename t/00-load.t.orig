use Test::More tests => 18;

BEGIN {
        use Class::C3;
        use MRO::Compat;

        use_ok( 'Artemis::Cmd::API::Command::upload' );
        use_ok( 'Artemis::Cmd::DbDeploy' );
        use_ok( 'Artemis::Cmd::Testrun::Command::delete' );
        use_ok( 'Artemis::Cmd::Testrun::Command::show' );
        use_ok( 'Artemis::Cmd::Testrun::Command::newprecondition' );
        use_ok( 'Artemis::Cmd::Testrun::Command::deleteprecondition' );
        use_ok( 'Artemis::Cmd::Testrun::Command::updateprecondition' );
        use_ok( 'Artemis::Cmd::Testrun::Command::new' );
        use_ok( 'Artemis::Cmd::Testrun::Command::update' );
        use_ok( 'Artemis::Cmd::Testrun::Command::listprecondition' );
        use_ok( 'Artemis::Cmd::Testrun::Command::list' );
        use_ok( 'Artemis::Cmd::DbDeploy::Command::makeschemadiffs' );
        use_ok( 'Artemis::Cmd::DbDeploy::Command::init' );
        use_ok( 'Artemis::Cmd::DbDeploy::Command::upgrade' );
        use_ok( 'Artemis::Cmd::DbDeploy::Command::saveschema' );
        use_ok( 'Artemis::Cmd::API' );
        use_ok( 'Artemis::Cmd::Testrun' );
        use_ok( 'Artemis::Cmd' );
}

diag( "Testing Artemis::Cmd $Artemis::Cmd::VERSION, Perl $], $^X" );
