use Test::More;

use Class::C3;
use MRO::Compat;

my @modules = (
               'Artemis::CLI',
               'Artemis::CLI::API',
               'Artemis::CLI::API::Command::download',
               'Artemis::CLI::API::Command::upload',
               'Artemis::CLI::DbDeploy',
               'Artemis::CLI::DbDeploy::Command::init',
               'Artemis::CLI::DbDeploy::Command::makeschemadiffs',
               'Artemis::CLI::DbDeploy::Command::saveschema',
               'Artemis::CLI::DbDeploy::Command::upgrade',
               'Artemis::CLI::Testrun',
               'Artemis::CLI::Testrun::Command::delete',
               'Artemis::CLI::Testrun::Command::deletehost',
               'Artemis::CLI::Testrun::Command::deleteprecondition',
               'Artemis::CLI::Testrun::Command::deletequeue',
               'Artemis::CLI::Testrun::Command::freehost',
               'Artemis::CLI::Testrun::Command::list',
               'Artemis::CLI::Testrun::Command::listhost',
               'Artemis::CLI::Testrun::Command::listprecondition',
               'Artemis::CLI::Testrun::Command::listqueue',
               'Artemis::CLI::Testrun::Command::new',
               'Artemis::CLI::Testrun::Command::newhost',
               'Artemis::CLI::Testrun::Command::newprecondition',
               'Artemis::CLI::Testrun::Command::newqueue',
               'Artemis::CLI::Testrun::Command::newscenario',
               'Artemis::CLI::Testrun::Command::rerun',
               'Artemis::CLI::Testrun::Command::show',
               'Artemis::CLI::Testrun::Command::updatehost',
               'Artemis::CLI::Testrun::Command::updateprecondition',
               'Artemis::CLI::Testrun::Command::updatequeue',
              );

plan tests => int @modules;

foreach my $module(@modules) {
        require_ok($module);
}


diag( "Testing Artemis::CLI $Artemis::CLI::VERSION, Perl $], $^X" );
