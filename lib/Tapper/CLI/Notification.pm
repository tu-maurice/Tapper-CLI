package Tapper::CLI::Notification;

use 5.010;
use warnings;
use strict;

use YAML::XS;
use Tapper::Cmd::Notification;

=head1 NAME

Tapper::CLI::Notification - Tapper - notification commands for the tapper CLI

=head1 SYNOPSIS

This module is part of the Tapper::CLI framework. It is supposed to be
used together with App::Rad. All following functions expect their
arguments as $c->options->{$arg}.

    use App::Rad;
    use Tapper::CLI::Notification;
    Tapper::CLI::Notification::setup($c);
    App::Rad->run();

=head1 FUNCTIONS

=head2 newnotification

Register new notification subscriptions.

@param file - contains the new subscription in YAML, multiple can be given
@optparam user - overwrite user information given in the file or set if none
@optparam verbose - be more chatty
@optparam help    - print out help message and die

=cut

sub newnotification
{
        my ($c) = @_;
        $c->getopt( 'file|f=s', 'user|u=s','verbose|v', 'help|?' );

        if (not %{$c->options} or $c->options->{help} ) {
                say STDERR "Usage: $0 newnotification --file=filename [ --user=login ] [ --verbose ]";
                say STDERR "\n\  Required Arguments:";
                say STDERR "\t--file\t\tname of file containing the notification subscriptions in YAML (required)";
                say STDERR "\n  Optional arguments:";
                say STDERR "\t--user\t\tset this user for all notification subscriptions (even if a different one is set in YAML)";
                say STDERR "\t--verbose\tbe more chatty";
                say STDERR "\t--help\t\tprint this help message and exit";
                exit -1;
        }

        my $cmd = Tapper::Cmd::Notification->new();
        my $user = $c->options->{user};

        my @ids;
        my @subscriptions =  YAML::XS::LoadFile($c->options->{file});
        foreach my $subscription (@subscriptions) {
                if ($user) {
                        $subscription->{user_login} = $user;
                        delete $subscription->{user_login};
                }
                push @ids, $cmd->add($subscription);
        }
        my $msg;
        $msg  = "The notification subscriptions were registered with the following ids:" if $c->options->{verbose};
        $msg .= join ",", @ids;
        return $msg;
}

=head2 listnotification

Show all or a subset of notification subscriptions

@optparam

=cut

sub listnotification
{
        my ($c) = @_;
        my $cmd = Tapper::Cmd::Notification->new();
        my $subscription_result = $cmd->list();
        while (my $this_subscription = $subscription_result->next) {
                delete $this_subscription->{created_at};
                delete $this_subscription->{updated_at};
                print YAML::XS::Dump($this_subscription);
        }
        return;
}

=head2 updatenotification

Update an existing notification subscription.

@param file - name of the file containing the new data for subscription notification in YAML
@param id   - id of the notification subscription to update
@optparam verbose - be more chatty
@optparam help    - print out help message and die

=cut

sub updatenotification
{
        my ($c) = @_;
        $c->getopt( 'file|f=s', 'id|i=i','verbose|v', 'help|?' );

        if (not %{$c->options} or $c->options->{help} ) {
                say STDERR "Usage: $0 updatenotification --file=filename --id=id [ --verbose ]";
                say STDERR "\n\  Required Arguments:";
                say STDERR "\t--file\t\tname of file containing the notification subscriptions in YAML";
                say STDERR "\t--id\t\tid of the notification subscriptions";
                say STDERR "\n  Optional arguments:";
                say STDERR "\t--verbose\tbe more chatty";
                say STDERR "\t--help\t\tprint this help message and exit";
                exit -1;
        }

        my $cmd = Tapper::Cmd::Notification->new();

        my $subscription =  YAML::XS::LoadFile($c->options->{file});
        my $id = $cmd->update($c->options->{id}, $subscription);

        return "The notification subscription was updated:" if $c->options->{verbose};
        return $id;
}

=head2 delnotification

Delete an existing notification subscription.

@param id   - id of the notification subscription to delete
@optparam verbose - be more chatty
@optparam help    - print out help message and die


=cut

sub delnotification
{
        my ($c) = @_;
        $c->getopt( 'id|i=i','verbose|v', 'help|?' );

        if (not %{$c->options} or $c->options->{help} ) {
                say STDERR "Usage: $0 newnotification --file=filename [ --user=login ] [ --verbose]";
                say STDERR "\n\  Required Arguments:";
                say STDERR "\t--file\t\tname of file containing the notification subscriptions in YAML (required)";
                say STDERR "\t--file\t\tname of file containing the notification subscriptions in YAML (required)";
                say STDERR "\n  Optional arguments:";
                say STDERR "\t--verbose\tbe more chatty";
                say STDERR "\t--help\t\tprint this help message and exit";
                exit -1;
        }

        my $cmd = Tapper::Cmd::Notification->new();

        my $id = $cmd->del($c->options->{id});

        return "The notification subscription was deleted." if $c->options->{verbose};
        return;
}



=head2 setup

Initialize the notification functions for tapper CLI

=cut

sub setup
{
        my ($c) = @_;
        $c->register('newnotification', \&newnotification, 'Register a new notification subscription');
        $c->register('listnotification', \&listnotification, 'Show all notification subscriptions');
        $c->register('updatenotification', \&updatenotification, 'Update an existing notification subscription');
        $c->register('delnotification', \&delnotification, 'Delete an existing notification subscription');
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
