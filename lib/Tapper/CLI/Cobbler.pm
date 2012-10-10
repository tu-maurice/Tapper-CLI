package Tapper::CLI::Cobbler;

use 5.010;
use warnings;
use strict;

use Tapper::Model 'model';
use Tapper::Config;
use Net::OpenSSH;

=head1 NAME

Tapper::CLI::Cobbler - Tapper - cobbler related commands for the tapper CLI

=head1 SYNOPSIS

This module is part of the Tapper::CLI framework. It is supposed to be
used together with App::Rad. All following functions expect their
arguments as $c->options->{$arg}.

    use App::Rad;
    use Tapper::CLI::Cobbler;
    Tapper::CLI::Cobbler::setup($c);
    App::Rad->run();

=head1 FUNCTIONS

=cut

# get_mac_address
#
# Retrieve the mac address of a host from features available in DB.
#
# @param Tapper::Schema::TestrunDB::Result::Host - host object
#
# @return string - mac address

sub get_mac_address
{
        my ($host) = @_;
        my ($retval) = map{$_->value} grep{ $_->entry eq 'mac_address'} $host->features->all;
        return $retval;
}

=head2 host_new

Add a new system to cobbler by copying from an existing one.

=cut

sub host_new
{
        my ($c) = @_;
        $c->getopt( 'from', 'name=s', 'quiet|q', 'help|?' );
        if ( $c->options->{help} or not $c->options->{name}) {
                say STDERR "Missing required parameter --name!" unless $c->options->{name};
                say STDERR "$0 cobbler-host-new  --name=s [ --quiet|q ] [ --from=s ]";
                say STDERR "\n\  Required Arguments:";
                say STDERR "        --name             Name of the new system";
                say STDERR "\n  Optional arguments:";
                say STDERR "        --from             Copy values of that system, default value is 'default'";
                say STDERR "        --quit             Stay silent";
                say STDERR "        --help             Print this help message and exit";
                exit -1;
        }
        my $name    = $c->options->{name};
        my $default = $c->options->{default} || 'default';
        my $cfg     = Tapper::Config->subconfig;
        my $cobbler_host = $cfg->{cobbler}->{host};

        my $host    = model('TestrunDB')->resultset('Host')->find({name => $name});
        die "Host '$name' does not exist in the database\n" if not $host;

        my $mac = get_mac_address($host);
        my $command = "cobbler system copy --name $default --newname $name --mac-address $mac";

        my $output;
        if ($cobbler_host) {
                my $user = $cfg->{cobbler}->{user};
                my $ssh = Net::OpenSSH->new("$user\@$cobbler_host");
                $ssh->error and die "ssh  $user\@$cobbler_host failed: ".$ssh->error;
                $output = $ssh->capture($command);
        } else {
                $output = qx( $command );
        }
        die $output if $output;

        if (not $c->options->{quiet}) {
                return "Added host $name to cobbler";
        }
        return;
}

=head2 host_del

Delete existing system from cobbler.

=cut

sub host_del
{
        my ($c) = @_;
        $c->getopt( 'name=s', 'quiet|q', 'help|?' );
        if ( $c->options->{help} or not $c->options->{name}) {
                say STDERR "Missing required parameter --name!" unless $c->options->{name};
                say STDERR "$0 cobbler-host-del  --name=s [ --quiet|q ]";
                say STDERR "\n\  Required Arguments:";
                say STDERR "        --name             Name of the new system";
                say STDERR "\n  Optional arguments:";
                say STDERR "        --quit             Stay silent";
                say STDERR "        --help             Print this help message and exit";
                exit -1;
        }
        my $name    = $c->options->{name};
        my $cfg     = Tapper::Config->subconfig;
        my $cobbler_host = $cfg->{cobbler}->{host};

        my $host    = model('TestrunDB')->resultset('Host')->find({name => $name});
        die "Host '$name' does not exist in the database\n" if not $host;

        my $command = "cobbler system remove --name $name";

        my $output;
        if ($cobbler_host) {
                my $user = $cfg->{cobbler}->{user};
                my $ssh = Net::OpenSSH->new("$user\@$cobbler_host");
                $ssh->error and die "ssh  $user\@$cobbler_host failed: ".$ssh->error;
                $output = $ssh->capture($command);
        } else {
                $output = qx( $command );
        }
        die $output if $output;

        if (not $c->options->{quiet}) {
                return "Host $name removed from cobbler";
        }
        return;
}


=head2 setup

Initialize the testplan functions for tapper CLI

=cut

sub setup
{
        my ($c) = @_;
        $c->register('cobbler-host-new', \&host_new,  'Add a new host to cobbler by copying from existing one');
        $c->register('cobbler-host-del', \&host_del,  'Remove an existing host from cobbler');
        if ($c->can('group_commands')) {
                $c->group_commands('Cobbler commands', 'cobbler-host-new', 'cobbler-host-del' );
        }
        return;
}

=head1 AUTHOR

AMD OSRC Tapper Team, C<< <tapper at amd64.org> >>

=head1 BUGS


=head1 COPYRIGHT & LICENSE

Copyright 2008-2011 AMD OSRC Tapper Team, all rights reserved.

This program is released under the following license: freebsd


=cut

1; # End of Tapper::CLI
