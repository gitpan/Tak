package Tak;

use Tak::Loop;
use strictures 1;

our $VERSION = '0.001001'; # 0.1.1

our $loop;

sub loop { $loop ||= Tak::Loop->new }

sub loop_until {
  my ($class, $done) = @_;
  return if $done;
  my $loop = $class->loop;
  $loop->loop_once until $_[1];
}

sub await_all {
  my ($class, @requests) = @_;
  @requests = grep !$_->is_done, @requests;
  return unless @requests;
  my %req = map +("$_" => "$_"), @requests;
  my $done;
  my %on_r = map {
    my $orig = $_->{on_result};
    my $tag = $req{$_};
    ($_ => sub { delete $req{$tag}; $orig->(@_); $done = 1 unless keys %req; })
  } @requests;
  my $call = sub { $class->loop_until($done) };
  foreach (@requests) {
    my $req = $_;
    my $inner = $call;
    $call = sub { local $req->{on_result} = $on_r{$req}; $inner->() };
  }
  $call->();
  return;
}

"for lexie";

=head1 NAME

Tak - Multi host remote control over ssh

=head1 SYNOPSIS

  bin/tak -h user1@host1 -h user2@host2 exec cat /etc/hostname

or

  in Takfile:

  package Tak::MyScript;
  
  use Tak::Takfile;
  use Tak::ObjectClient;
  
  sub each_get_homedir {
    my ($self, $remote) = @_;
    my $oc = Tak::ObjectClient->new(remote => $remote);
    my $home = $oc->new_object('Path::Class::Dir')->absolute->stringify;
    $self->stdout->print(
      $remote->host.': '.$home."\n"
    );
  }
  
  1;

then

  tak -h something get-homedir

=head1 WHERE'S THE REST?

A drink leaked in my bag on the way back from LPW. You'll get more once I
get my laptop's drive into an enclosure and decant the slides.

=head1 AUTHOR

mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

None required yet. Maybe this module is perfect (hahahahaha ...).

=head1 COPYRIGHT

Copyright (c) 2011 the strictures L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
