package Tak::ModuleSender;

use IO::All;
use Moo;

with 'Tak::Role::Service';

sub handle_source_for {
  my ($self, $module) = @_;
  my $io = io->dir("$ENV{HOME}/perl5/lib/perl5")->catfile($module);
  unless ($io->exists) {
    die [ 'failure' ];
  }
  my $code = $io->all;
  return $code;
}

1;
