#! /usr/bin/env perl

use strict;
use warnings;

use Cwd;
use Test::More;
use File::Temp 'tempfile';
use Artemis::CLI::Testrun;
use Artemis::CLI::Testrun::Command::list;
use Artemis::Schema::TestTools;
use Artemis::Model 'model';
use Test::Fixture::DBIC::Schema;
use File::Slurp 'slurp';
use Artemis::Reports::API::Daemon;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => reportsdb_schema, fixture => 't/fixtures/reportsdb/report.yml' );
# -----------------------------------------------------------------------------------------------------------------

# ____________________ START SERVER ____________________

$ENV{MX_DAEMON_STDOUT} = getcwd."/test-artemis_reports_api_daemon_stdout.log";
$ENV{MX_DAEMON_STDERR} = getcwd."/test-artemis_reports_api_daemon_stderr.log";

my $grace_period = 5;
my $port = Artemis::Config->subconfig->{report_api_port};
my $api  = new Artemis::Reports::API::Daemon (
                                              basedir => getcwd,
                                              pidfile => getcwd.'/test-artemis-reports-api-daemon-test.pid',
                                              port    => $port,
                                             );
$api->run("start");
sleep $grace_period;

# ____________________ UPLOAD/DOWNLOAD ____________________

my $file     = 't/dummy-attachment.txt';
my $upload   = `/usr/bin/env perl -Ilib bin/artemis-api upload   --reportid 23 --file "$file"`;
my $download = `/usr/bin/env perl -Ilib bin/artemis-api download --reportid 23 --file "$file"`;
my $expected = slurp $file;
is ($download, $expected, "downloaded file is uploaded file");

# ____________________ UPLOAD TWICE / DOWNLOAD 2ND ____________________

# one file, (used twice)
my ($FH, $file1) = tempfile( UNLINK => 1 );

# first
my $content1 = slurp $file;
print $FH $content1;
close $FH;
$upload = `/usr/bin/env perl -Ilib bin/artemis-api upload   --reportid 23 --file "$file1"`;

# second
my $content2 = $content1."ZOMTEC";
open $FH, ">", $file1 or die "Cannot write $file1";
print $FH $content2;
close $FH;
$upload = `/usr/bin/env perl -Ilib bin/artemis-api upload   --reportid 23 --file "$file1"`;

# download first
$expected = $content1;
$download = `/usr/bin/env perl -Ilib bin/artemis-api download --reportid 23 --file "$file1"`;
is ($download, $expected, "downloaded 1st file is uploaded file");

# downloaded first with explicit index
$expected = $content1;
$download = `/usr/bin/env perl -Ilib bin/artemis-api download --reportid 23 --file "$file1" --index=0`;
is ($download, $expected, "downloaded 1st file with explicit index is uploaded file");

$expected = $content2;
$download = `/usr/bin/env perl -Ilib bin/artemis-api download --reportid 23 --file "$file1" --nth=1`;
is ($download, $expected, "downloaded 2nd file is uploaded file");

# ____________________ CLOSE SERVER ____________________

#sleep 60;
$api->run("stop");

done_testing();
