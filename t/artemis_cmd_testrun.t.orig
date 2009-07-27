#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Artemis::Cmd::Testrun;
use Artemis::Cmd::Testrun::Command::list;
use Artemis::Cmd::Testrun::Command::new;
use Artemis::Cmd::Testrun::Command::newprecondition;
use Artemis::Cmd::Testrun::Command::listprecondition;
use Artemis::Schema::TestTools;
use Artemis::Model 'model';
use Test::Fixture::DBIC::Schema;

plan tests => 29;

# --------------------------------------------------

my $OK_YAML = '
---
file_order:
  - t/00-artemis-meta.t
  - t/00-load.t
  - t/artemis_logging_netlogappender.t
  - t/artemis_mcp_builder.t
  - t/artemis_mcp_runtest.t
  - t/artemis_model.t
  - t/artemis_systeminstaller.t
  - t/artemis.t
  - t/boilerplate.t
  - t/experiments.t
start_time: 1213352566
stop_time: 1213352568
';

my $ERR_YAML = '
---
file_order:
  - t/experiments.t
start_time: 1213352566
  stop_time: 1213352568
';

is(Artemis::Cmd::Testrun::_yaml_ok($OK_YAML), 1, "ok_yaml with correct yaml");
is(Artemis::Cmd::Testrun::_yaml_ok($ERR_YAML), 0, "ok_yaml with error yaml");

# --------------------------------------------------


# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_preconditions.yml' );
# -----------------------------------------------------------------------------------------------------------------
# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => hardwaredb_schema, fixture => 't/fixtures/hardwaredb/systems.yml' );
# -----------------------------------------------------------------------------------------------------------------

my $testrun = Artemis::Cmd::Testrun::Command::list::_get_entry_by_id (23); # perfmon

is($testrun->id, 23, "testrun id");
is($testrun->notes, 'perfmon', "testrun notes");
is($testrun->shortname, 'perfmon', "testrun shortname");
is($testrun->topic_name, 'Software', "testrun topic_name");
is($testrun->topic->name, 'Software', "testrun topic->name");
is($testrun->topic->description, 'any non-kernel software, e.g., libraries, programs', "testrun topic->description");

is(Artemis::Cmd::Testrun::_get_user_id_for_login('sschwigo'), 12, "_get_user_id_for_login / existing");
is(Artemis::Cmd::Testrun::_get_user_id_for_login('nonexistentuser'), 0, "_get_user_id_for_login / nonexisting");


# --------------------------------------------------

# TODO: {
#         local $TODO = 'do not forget to implement some subs';

#         isnt(Artemis::Cmd::Testrun::_get_systems_id_for_hostname("affe"), 42, "_get_systems_id_for_hostname");
# }

my $precond_id = `/usr/bin/env perl -Ilib bin/artemis-testrun newprecondition --shortname="perl-5.10" --condition="affe:"`;
chomp $precond_id;

my $precond = model('TestrunDB')->resultset('Precondition')->find($precond_id);
ok($precond->id, 'inserted precond / id');
is($precond->shortname, "perl-5.10", 'inserted precond / shortname');
is($precond->precondition, "affe:\n", 'inserted precond / yaml');

# --------------------------------------------------

my $old_precond_id = $precond_id;
$precond_id = `/usr/bin/env perl -Ilib bin/artemis-testrun updateprecondition --id=$old_precond_id --shortname="foobar-perl-5.11" --condition="not_affe_again:"`;
chomp $precond_id;

$precond = model('TestrunDB')->resultset('Precondition')->find($precond_id);
is($precond->id, $old_precond_id, 'update precond / id');
is($precond->shortname, 'foobar-perl-5.11', 'update precond / shortname');
is($precond->precondition, 'not_affe_again:', 'update precond / yaml');

# --------------------------------------------------

my $testrun_id = `/usr/bin/env perl -Ilib bin/artemis-testrun new --topic=Software --hostname=iring --precondition=1`;
chomp $testrun_id;

$testrun = model('TestrunDB')->resultset('Testrun')->find($testrun_id);
ok($testrun->id, 'inserted testrun / id');
is($testrun->hardwaredb_systems_id, 12, 'inserted testrun / systems_id');

# --------------------------------------------------

my $old_testrun_id = $testrun_id;
$testrun_id = `/usr/bin/env perl -Ilib bin/artemis-testrun update --id=$old_testrun_id --topic=Hardware --hostname=iring`;
chomp $testrun_id;

$testrun = model('TestrunDB')->resultset('Testrun')->find($testrun_id);
is($testrun->id, $old_testrun_id, 'updated testrun / id');
is($testrun->topic_name, "Hardware", 'updated testrun / topic');
is($testrun->hardwaredb_systems_id, 12, 'updated testrun / systems_id');

# --------------------------------------------------

`/usr/bin/env perl -Ilib bin/artemis-testrun delete --id=$testrun_id --really`;
$testrun = model('TestrunDB')->resultset('Testrun')->find($testrun_id);
is($testrun, undef, "delete testrun");

`/usr/bin/env perl -Ilib bin/artemis-testrun deleteprecondition --id=$precond_id --really`;
$precond = model('TestrunDB')->resultset('Precondition')->find($precond_id);
is($precond, undef, "delete precond");

# --------------------------------------------------

$testrun_id = `/usr/bin/env perl -Ilib bin/artemis-testrun new --macroprecond=t/files/kernel_boot.mpc -Dkernel_version=2.6.19 --hostname=iring`;
chomp $testrun_id;
$testrun = model('TestrunDB')->resultset('Testrun')->search({id => $testrun_id,})->first();

my @precond_array = $testrun->ordered_preconditions;

is($precond_array[0]->precondition_as_hash->{precondition_type}, "package",'Parsing macropreconditions, first sub precondition');
is($precond_array[1]->precondition_as_hash->{precondition_type}, "exec",'Parsing macropreconditions, second sub precondition');
is($precond_array[1]->precondition_as_hash->{options}->[0], "2.6.19",'Parsing macropreconditions, template toolkit substitution');
is($precond_array[0]->precondition_as_hash->{filename}, "kernel/linux-2.6.19.tar.gz",'Parsing macropreconditions, template toolkit with if block');

$testrun_id = `/usr/bin/env perl -Ilib bin/artemis-testrun new --macroprecond=t/files/kernel_boot.mpc --hostname=iring 2>&1`;
chomp $testrun_id;
like($testrun_id, qr/Expected macro field 'kernel_version' missing./, "missing mandatory field recognized");

$testrun_id = `/usr/bin/env perl -Ilib bin/artemis-testrun new --hostname=iring 2>&1`;
chomp $testrun_id;
like($testrun_id, qr/At least one of .+ is required./, "Prevented testrun without precondition");
