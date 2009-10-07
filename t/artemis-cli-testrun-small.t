#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Artemis::CLI::Testrun;
use Artemis::Schema::TestTools;
use Artemis::Model 'model';
use Test::Fixture::DBIC::Schema;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testruns_with_scheduling.yml' );
# -----------------------------------------------------------------------------------------------------------------
# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => hardwaredb_schema, fixture => 't/fixtures/hardwaredb/systems.yml' );
# -----------------------------------------------------------------------------------------------------------------

my $retval = `/usr/bin/env perl -Ilib bin/artemis-testrun list --id=4`;
like($retval, qr(4 \| foobar \| Used to provide hardware_id), 'List testrun / by id');

$retval = `/usr/bin/env perl -Ilib bin/artemis-testrun list --host=iring --schedule`;
is($retval, "3001\n3002\n", 'List testrun / by host, schedule');

done_testing();
