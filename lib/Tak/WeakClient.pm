package Tak::WeakClient;

use Moo;

extends 'Tak::Client';

has service => (is => 'ro', required => 1, weak_ref => 1);

1;
