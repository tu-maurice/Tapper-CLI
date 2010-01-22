#! /usr/bin/env perl

use strict;
use warnings;

use Test::Deep;
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

my $queue_id = `/usr/bin/env perl -Ilib bin/artemis-testrun newqueue  --name="Affe" --priority=4711`;
chomp $queue_id;

my $queue = model('TestrunDB')->resultset('Queue')->find($queue_id);
ok($queue->id, 'inserted queue / id');
is($queue->name, "Affe", 'inserted queue / name');
is($queue->priority, 4711, 'inserted queue / priority');

`/usr/bin/env perl -Ilib bin/artemis-testrun newhost  --name="host3" --queue=Xen --queue=KVM`;
is($?, 0, 'New host / return value');

my $retval = `/usr/bin/env perl -Ilib bin/artemis-testrun listqueue --maxprio=300 --minprio=200 -v `;
is ($retval, "Id: 2\nName: KVM\nPriority: 200\nActive: no\nBound hosts: host3\n
********************************************************************************
Id: 1\nName: Xen\nPriority: 300\nActive: no\nBound hosts: host3\n
********************************************************************************
", 'List queues');
$retval = `/usr/bin/env perl -Ilib bin/artemis-testrun listqueue --maxprio=10 -v `;
is($retval, "Id: 3\nName: Kernel\nPriority: 10\nActive: no\nQueued testruns (ids): 301, 302\n
********************************************************************************
", 'Queued testruns in listqueue');

$retval = `/usr/bin/env perl -Ilib bin/artemis-testrun updatequeue --name=Xen -p500 -v`;
is($retval, "Xen | 500 | not active\n", 'Update queue priority');

$retval = `/usr/bin/env perl -Ilib bin/artemis-testrun updatequeue --name=Xen --active -v`;
is($retval, "Xen | 500 | active\n", 'Update queue active flag');

$retval = `/usr/bin/env perl -Ilib bin/artemis-testrun updatequeue --name=Xen --noactive -v`;
is($retval, "Xen | 500 | not active\n", 'Update queue active flag');


$retval = `/usr/bin/env perl -Ilib bin/artemis-testrun deletequeue --name=Xen --really`;
is($retval, "Deleted queue Xen\n", 'Delete queue');


done_testing();
