#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Artemis::CLI::Testrun;
use Artemis::CLI::Testrun::Command::list;
use Artemis::Schema::TestTools;
use Artemis::Model 'model';
use Test::Fixture::DBIC::Schema;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testruns_with_scheduling.yml' );
# -----------------------------------------------------------------------------------------------------------------
# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => hardwaredb_schema, fixture => 't/fixtures/hardwaredb/systems.yml' );
# -----------------------------------------------------------------------------------------------------------------

my $precond_id = `/usr/bin/env perl -Ilib bin/artemis-testrun newprecondition  --condition="affe: ~"`;
chomp $precond_id;

my $precond = model('TestrunDB')->resultset('Precondition')->find($precond_id);
ok($precond->id, 'inserted precond / id');
like($precond->precondition, qr"affe: ~", 'inserted precond / yaml');

# --------------------------------------------------

my $old_precond_id = $precond_id;
$precond_id = `/usr/bin/env perl -Ilib bin/artemis-testrun updateprecondition --id=$old_precond_id --shortname="foobar-perl-5.11" --condition="not_affe_again: ~"`;
chomp $precond_id;

$precond = model('TestrunDB')->resultset('Precondition')->find($precond_id);
is($precond->id, $old_precond_id, 'update precond / id');
is($precond->shortname, 'foobar-perl-5.11', 'update precond / shortname');
like($precond->precondition, qr'not_affe_again: ~', 'update precond / yaml');

my @retval = `/usr/bin/env perl -Ilib bin/artemis-testrun listprecondition --all`;
chomp @retval;
is_deeply(\@retval, [5, 6, 7, 8, 9, 10, 11, 101, 102, 103], 'List preconditions / all, short');

my $retval = `/usr/bin/env perl -Ilib bin/artemis-testrun listprecondition --id=5 -v`;
is($retval, "5 | temare_producer | ---\nprecondition_type: produce\nproducer: Temare\nsubject: KVM\nbitness: 64\n | NULL | \n", 'List preconditions / id, long');

@retval = `/usr/bin/env perl -Ilib bin/artemis-testrun listprecondition --testrun=3002`;
chomp @retval;
is_deeply(\@retval, [5, 8], 'List preconditions / per testrun, short');

@retval = `/usr/bin/env perl -Ilib bin/artemis-testrun updateprecondition  --shortname="foobar-perl-5.11" --condition="not_affe_again: ~" 2>&1`;
chomp @retval;
is($retval[0], "Required option missing: id", 'Update precondition / id');

`/usr/bin/env perl -Ilib bin/artemis-testrun deleteprecondition --id=$precond_id --really`;
$precond = model('TestrunDB')->resultset('Precondition')->find($precond_id);
is($precond, undef, "delete precond");



done_testing();
