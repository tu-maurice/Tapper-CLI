package Artemis::CLI::Testrun::Command::list;

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Data::Dumper;
use Artemis::Model 'model';
use Artemis::Schema::TestrunDB;

sub abstract {
        'List testruns'
}

my $options = { "verbose"   => { text => "print all output, without only print ids", short => 'v' },
                "colnames"  => { text => "print out column names" },
                "all"       => { text => "list all testruns", short => 'a' },
                "finished"  => { text => "list finished testruns, OR combined with other state filters", filter => 1, short => 'f'},
                "running"   => { text => "list running testruns, OR combined with other state filters", filter => 1, short => 'r' },
                "schedule"  => { text => "list scheduled testruns, OR combined with other state filters", filter => 1, short => 's' },
                "prepare"   => { text => "list testruns not yet in any scheduling queue, OR combined with other state filters", filter => 1, short => 'p' },
                "queue"     => { text => "list testruns assigned to this queue, OR combined with other queues, AND combined with other filters", filter => 1, type => 'manystring'},
                "host"      => { text => "list testruns assigned to this queue, OR combined with other hosts, AND combined with other filters", filter => 1, type => 'manystring'},
                "id"        => { text => "list particular testruns", type => 'int', short => 'i' },

              };
                

sub opt_spec {
        my @opt_spec;
        foreach my $key (keys %$options) {
                my $pushkey = $key;
                $pushkey    = $pushkey."|".$options->{$key}->{short} if $options->{$key}->{short};

                given($options->{$key}->{type}){
                        when ("string")        {$pushkey .="=s";}
                        when ("withno")        {$pushkey .="!";}
                        when ("manystring")    {$pushkey .="=s@";}
                        when ("optmanystring") {$pushkey .=":s@";}
                        when ("int")           {$pushkey .="=i";}
                        when ("multiint")      {$pushkey .="=i@";}
                        when ("keyvalue")      {$pushkey .="=s%";}
                }
                push @opt_spec, [$pushkey, $options->{$key}->{text}];
        }
        return (
                @opt_spec
               );
}

sub usage_desc {
        my $allowed_opts = join ' | ', map { '--'.$_ } _allowed_opts();
        "artemis-testruns listprecondition [ " . $allowed_opts ." ]";
}

sub _allowed_opts {
        my @allowed_opts = map { $_->[0] } opt_spec();
}

sub _extract_bare_option_names {
        map { s/=.*//; $_} _allowed_opts();
}

sub validate_args {
        my ($self, $opt, $args) = @_;
        my @allowed_opts;
        foreach my $key (keys %$options) {
                push @allowed_opts, $key if  $options->{$key}->{filter};
        }
        if ($opt->{all} ) {
                say STDERR "You provided --all and a filter option. Filter options imply --all which can be left out in this case" if @allowed_opts;
                push @allowed_opts, 'all';
                
        }
        
        if ($opt->{id}) {
                if ($opt->{all}) {
                        say STDERR "--id can not be used together --all";
                        die $self->usage_desc;
                } elsif (@allowed_opts) {
                        say STDERR "--id can not be used together with filter options";
                        die $self->usage_desc;
                } 
                push @allowed_opts, 'id';
        }

        
        my $msg = "Unknown option";
        $msg   .= ($args and $#{$args} >=1) ? 's' : '';
        $msg   .= ": ";
        say STDERR $msg, join(', ',@$args) if ($args and @$args);
        
        
        my $allowed_opts_re = join '|', @allowed_opts;

        return 1 if grep /$allowed_opts_re/, keys %$opt;
        die $self->usage_desc->text;
}

sub run {
        my ($self, $opt, $args) = @_;
        $self->print_colnames if $opt->{colnames};
        my $use_flag;
        my $testrun_rs;
        my @opts;

        if ($opt->{id}) {
                # don't use find so we can use common print function for id and filtered below
                $testrun_rs = model('TestrunDB')->resultset('Testrun')->search({id => $opt->{id}});

        } else {
                my @ids;
                $testrun_rs = model('TestrunDB')->resultset('Testrun');
        STATE:
                foreach my $state (qw(finished running schedule prepare)) {
                        next STATE if not $opt->{$state};
                        my $schedule_rs = model('TestrunDB')->resultset('TestrunScheduling')->search({status => $state});
                        push @ids, map {$_->testrun_id} $schedule_rs->all;
                        $use_flag=1;
                }
                $testrun_rs = $testrun_rs->search({id =>[ @ids ] }) if $use_flag;  # @ids may be empty if no state filter or filter results in 0 tests found

                
                @ids = (); $use_flag = 0;
        QUEUE:
                foreach my $queue (@{$opt->{queue}}) {
                        my $queue_r = model('TestrunDB')->resultset('Queue')->search({name => $queue});
                        warn "No such such queue: $queue", next QUEUE if not $queue_r;
                        push @ids, map {$_->testrun->id} $queue_r->first->testrunschedulings->all;
                        $use_flag=1;
                }
                $testrun_rs = $testrun_rs->search({id => [ @ids ] }) if $use_flag;


                @ids = (); $use_flag = 0;
        HOST:
                foreach my $host (@{$opt->{host}}) {
                        my $host_r = model('TestrunDB')->resultset('Host')->search({name => $host});
                        warn "No such such host: $host", next HOST if not $host_r;
                        my $requested_host_r = model('TestrunDB')->resultset('TestrunRequestedHost')->search({host_id => [ map {$_->id} $host_r->all ]});
                        foreach my $requested_host ($requested_host_r->all) {
                                push @ids, $requested_host->testrunscheduling->id;
                        }
                        $use_flag=1;
                }
                $testrun_rs = $testrun_rs->search({id => [ @ids ] }) if $use_flag;
        }
        
        foreach my $testrun ($testrun_rs->all) {
                if ($opt->{verbose}) {
                        say $testrun->to_string;
                } else {
                        say $testrun->id;

                }
        }
}

sub print_colnames
{
        my ($self, $opt, $args) = @_;


        my $columns = model('TestrunDB')->resultset('Testrun')->result_source->{_ordered_columns};
        print join( $Artemis::Schema::TestrunDB::DELIM, @$columns, '' ), "\n";
}


# --------------------------------------------------

sub _get_entry_by_id {
        my ($id) = @_;
        model('TestrunDB')->resultset('Testrun')->find($id);
}

1;

# perl -Ilib bin/artemis-testrun list --id 16
