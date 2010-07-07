package Artemis::CLI::Testrun::Command::freehost;

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Artemis::Model 'model';
use Artemis::CLI::Testrun;
use Artemis::Config;

use IO::Socket::INET;
use YAML::Syck;

sub abstract {
        'Update an existing host'
}


my $options =  {
                "verbose"          => { text => "some more informational output", short=> 'v' },
                "name"             => { text => "TEXT; free host with this name",    type => 'string' },
                "desc"             => { text => "TEXT; describe why the host is freed",    type => 'string' },
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
                        when ("keyvalue")      {$pushkey .="=s%";}
                }
                push @opt_spec, [$pushkey, $options->{$key}->{text}];
        }
        return (
                @opt_spec
               );
}


sub validate_args
{
        my ($self, $opt, $args) = @_;

        die "Missing argument --name" unless  $opt->{name};
        return 1;
}

=head2 free_host

Send message to MCP and tell it to cancle the currently running test on
given host. Requires the install config for this host on the same
machine.

@param host object - host to free
@param hash ref    - options

@return 0

@throws untyped exception

=cut

sub free_host
{
        my ($self, $host, $opt) = @_;
        my $cfg = Artemis::Config::subconfig();
        my $file = $cfg->{paths}{localdata_path}.$host->name."-install";
        my $mcp_config = LoadFile($file);
        die "Can't get MCP port from $file, unable to send quit signal" if not $mcp_config->{mcp_port};
        my $sock = IO::Socket::INET->new(PeerAddr => $mcp_config->{mcp_host} || 'localhost',
                                         PeerPort => $mcp_config->{mcp_port});
        die ("Can not contact MCP on ",$mcp_config->{mcp_host} || 'localhost',":",$mcp_config->{mcp_port}," - $!") if not $sock;
        my $msg = "state: quit";
        $msg   .= "\nerror: $opt->{desc}" if $opt->{desc};
        $sock->say($msg);
        $sock->close();
        return 0;
}


sub execute 
{
        my ($self, $opt, $args) = @_;
        my $host = model('TestrunDB')->resultset('Host')->search(name => $opt->{name})->first;
        die "No such host: $opt->{name}" if not  $host;

        $self->free_host($host, $opt);
        say "Host $opt->{name} is free now";
}


1;
