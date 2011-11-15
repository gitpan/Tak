package Tak::Router;

use Tak::MetaService;
use Scalar::Util qw(weaken);
use Moo;

has services => (is => 'ro', default => sub { {} });

sub BUILD {
  my ($self) = @_;
  $self->register(meta => Tak::MetaService->new(router => $self));
}

sub start_request {
  my ($self, $req, $target, @payload) = @_;
  return $req->mistake("Reached router with no target")
    unless $target;
  return $req->failure("Reached router with invalid target ${target}")
    unless my $next = $self->services->{$target};
  $next->start_request($req, @payload);
}

sub receive {
  my ($self, $target, @payload) = @_;
  return unless $target;
  return unless my $next = $self->services->{$target};
  $next->receive(@payload);
}

sub register {
  my ($self, $name, $service) = @_;
  $self->services->{$name} = $service;
}

sub register_weak {
  my ($self, $name, $service) = @_;
  weaken($self->services->{$name} = $service);
}

sub deregister {
  my ($self, $name) = @_;
  delete $self->services->{$name}
}

1;
