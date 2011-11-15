package Tak::MetaService;

use Tak::WeakClient;
use Moo;

with 'Tak::Role::Service';

has router => (is => 'ro', required => 1, weak_ref => 1);

sub handle_pid {
  return $$;
}

sub handle_ensure {
  my $self = shift;
  my ($name) = @_;
  return "Already have ${name}" if $self->router->services->{$name};
  $self->handle_register(@_);
}

sub handle_register {
  my ($self, $name, $class, %args) = @_;
  (my $file = $class) =~ s/::/\//g;
  require "${file}.pm";
  if (my $expose = delete $args{expose}) {
    my $client = Tak::WeakClient->new(service => $self->router);
    foreach my $name (%$expose) {
      $args{$name} = $client->curry(@{$expose->{$name}});
    }
  }
  my $new = $class->new(\%args);
  $self->router->register($name => $new);
  return "Registered ${name}";
}

1;
