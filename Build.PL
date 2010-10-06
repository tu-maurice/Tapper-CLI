use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new
    (
     module_name         => 'Artemis::CLI',
     license             => 'restrictive',
     dist_author         => 'OSRC SysInt Team <osrc-sysint@elbe.amd.com>',
     dist_version_from   => 'lib/Artemis/CLI.pm',
     build_requires => {
                        'Test::More'                  => 0,
                        'Test::Perl::Critic'          => 0,
                        'Test::Fixture::DBIC::Schema' => 0,
                        'DBIx::Class'                 => '0.08112',
                        'Artemis::Test'               => '2.010005',
                        'SQL::Translator'             => '0.11003',
                       },
     requires => {
                  'perl'                      => '5.010',
                  'parent'                    => 0,
                  'App::Cmd'                  => '0.301',
                  'DBIx::Class::TimeStamp'    => 0,
                  'File::Slurp'               => 0,
                  'IO::Socket'                => 0,
                  'Template'                  => 0,
                  'Artemis::Model'            => '2.010003',
                  'Artemis::Config'           => '2.010003',
                  'Artemis::Schema'           => '2.010022',
                  'Artemis::Cmd'              => '2.010029',
                  'Data::Dumper'              => 0,
                  'DateTime::Format::Natural' => 0,
                  'YAML::Syck'                => 0,
                  'Moose'                     => 0,
	          'MooseX::LazyRequire'       => '0.06',
                 },
     add_to_cleanup      => [ 'Artemis-CLI-*' ],
    );

$builder->create_build_script();
