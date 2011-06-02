use strict;
use warnings;

use Test::More 0.96;

{
  package Foo;
  use Moose;
  use MooseX::Types::FakeHash;

  has str => (
    isa => 'KeyWith[ Str ]',
    is  => 'rw',
    required => 1,
  );

  __PACKAGE__->meta->make_immutable;
}

use Test::Fatal;

isnt( exception {
  my $instance = Foo->new();
}, undef , 'str attribute is required' );

isnt( exception {
  my $instance = Foo->new( str => 'Hello' );
}, undef, 'str is not a string' );

isnt( exception {
  my $instance = Foo->new( str => [] );
}, undef, 'str is not an empty array' );

isnt( exception {
  my $instance = Foo->new( str => [ 'foo' ] );
}, undef, 'str is not an array of length 1' );

is( exception {
  my $instance = Foo->new( str => [ 'foo', 'bar' ] );
}, undef, 'str is an array of length 2' );

isnt( exception {
  my $instance = Foo->new( str => [ 'foo', 'bar', 'baz' ] );
}, undef, 'str is not an array of length 3' );


isnt( exception {
  my $instance = Foo->new( str => [ 'foo', [] ] );
}, undef, 'str->[1] is not an empty array' );


done_testing;

