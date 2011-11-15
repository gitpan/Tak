package Tak::ConnectorService;

use IPC::Open2;
use IO::All;
use Tak::Router;
use Tak::Client;
use Tak::ConnectionService;
use Net::OpenSSH;
use Tak::STDIONode;
use Moo;

with 'Tak::Role::Service';

has connections => (is => 'ro', default => sub { Tak::Router->new });

has ssh => (is => 'ro', default => sub { {} });

sub handle_create {
  my ($self, $on, %args) = @_;
  my $log_level = $args{log_level}||'info';
  my ($kid_in, $kid_out, $kid_pid) = $self->_open($on, $log_level);
  $kid_in->print($Tak::STDIONode::DATA, "__END__\n");
  # Need to get a handshake to indicate STDIOSetup has finished
  # messing around with file descriptors, otherwise we can severely
  # confuse things by sending before the dup.
  my $up = <$kid_out>;
  die [ failure => "Garbled response from child: $up" ]
    unless $up eq "Ssyshere\n";
  my $connection = Tak::ConnectionService->new(
    read_fh => $kid_out, write_fh => $kid_in,
    listening_service => Tak::Router->new
  );
  my $client = Tak::Client->new(service => $connection);
  # actually, we should register with a monotonic id and
  # stash the pid elsewhere. but meh for now.
  my $pid = $client->do(meta => 'pid');
  my $name = ($on||'|').':'.$pid;
  my $conn_router = Tak::Router->new;
  $conn_router->register(local => $connection->receiver->service);
  $conn_router->register(remote => $connection);
  $self->connections->register($name, $conn_router);
  return ($name);
}

sub _open {
  my ($self, $on, @args) = @_;
  unless ($on) {
    my $kid_pid = IPC::Open2::open2(my $kid_out, my $kid_in, $^X, '-', '-', @args)
      or die "Couldn't open2 child: $!";
    return ($kid_in, $kid_out, $kid_pid);
  }
  my $ssh = $self->ssh->{$on} ||= Net::OpenSSH->new($on);
  $ssh->error and
    die "Couldn't establish ssh connection: ".$ssh->error;
  return $ssh->open2('perl','-', $on, @args);
}

sub start_connection_request {
  my ($self, $req, @payload) = @_;;
  $self->connections->start_request($req, @payload);
}

sub receive_connection {
  my ($self, @payload) = @_;
  $self->connections->receive(@payload);
}

1;
