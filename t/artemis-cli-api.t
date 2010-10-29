#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Artemis::CLI::Testrun;
use Artemis::CLI::Testrun::Command::list;
use Artemis::Schema::TestTools;
use Artemis::Model 'model';
use Test::Fixture::DBIC::Schema;
use File::Slurp 'slurp';

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => reportsdb_schema, fixture => 't/fixtures/reportsdb/report.yml' );
# -----------------------------------------------------------------------------------------------------------------

my $file     = 't/dummy-attachment.txt';
my $upload   = `/usr/bin/env perl -Ilib bin/artemis-api upload   --reportid 23 --file "$file"`;
my $download = `/usr/bin/env perl -Ilib bin/artemis-api download --reportid 23 --file "$file"`;

my $expected = slurp $file;
is ($download, $expected, "downloaded file is uploaded file");

done_testing();
