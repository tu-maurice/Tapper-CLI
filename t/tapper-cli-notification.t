#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => reportsdb_schema, fixture => 't/fixtures/reportsdb/report.yml' );
# -----------------------------------------------------------------------------------------------------------------




my $id = `$^X -Ilib bin/tapper notificationnew --file=t/files/notification.yml`;
chomp $id;
like($id, qr"^\d+$", 'New notification substitution registered');

my $list = `$^X -Ilib bin/tapper notificationlist`;
is($list, q{---
comment: Testrun id 42 finished
condition: testrun('id') == 42
event: testrun_finished
id: 1
persist: 1
user_id: 1
},'List of notifications after notificationnew');

$id = `$^X -Ilib bin/tapper notificationupdate --file=t/files/notification_updated.yml --id=$id`;
chomp $id;
like($id, qr"^\d+$", 'New notification substitution registered');

$list = `$^X -Ilib bin/tapper notificationlist`;
is($list, q{---
comment: Testrun id 43 finished
condition: testrun('id') == 43
event: testrun_finished
id: 1
persist: 1
user_id: 1
},'List of notifications after notificationupdate');


$list = `$^X -Ilib bin/tapper notificationdel --id=$id`;
$list = `$^X -Ilib bin/tapper notificationlist`;
is($list, '','List of notifications after notificationdel');


done_testing();
