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
my @words = $retval =~ m/ *(\d+)(?: |\|)*(\w+)(?: |\|)*(\d+)(?:(?: |\|)*(\w+))/mg;
is_deeply(\@words,[2,'KVM', 200, 'host3', 1, 'Xen', 300, 'host3'], 'Listqueue / verbose');

$retval = `/usr/bin/env perl -Ilib bin/artemis-testrun updatequeue --name=Xen -p500 -v`;
is($retval, "Xen | 500\n", 'Update queue');

$retval = `/usr/bin/env perl -Ilib bin/artemis-testrun deletequeue --name=Xen --really`;
is($retval, "Deleted queue Xen\n", 'Delete queue');


done_testing();
