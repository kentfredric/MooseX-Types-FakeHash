use strict;
use warnings;

package MooseX::Types::FakeHash;

# ABSTRACT: Types for emulating Hash-like behaviours with ArrayRefs.

use Moose::Meta::TypeConstraint::Parameterizable;
use MooseX::Types;
use Moose::Util::TypeConstraints ();

=head1 SYNOPSIS

=head2 Standard Non-MooseX-Types style invocation

  package #
    Foo;

  use Moose;
  use MooseX::Types::FakeHash;

  has foo => (
    isa => 'KeyWith[ ArrayRef ]'
    is  => 'rw',
    required => 1,
  );

  has bar => (
    isa      => 'ArrayRef[ KeyWith[ Str ] ]',
    is       => 'rw',
    required => 1,
  );

  ....


  Foo->new(
    foo => [ Hello => [] ]
    bar => [
       [ "Content-Type" => "text/plain" ],
       [ "X-Zombies"    => "0"          ],
    ],
  );


=head2 MooseX-Types style invocation

  package #
    Foo;

  use Moose;
  use MooseX::Types::FakeHash qw( :all );
  use MooseX::Types::Moose    qw( :all );

  has foo => (
    isa => KeyWith[ ArrayRef ]
    is  => 'rw',
    required => 1,
  );

  has bar => (
    isa      => ArrayRef[ KeyWith[ Str ] ],
    is       => 'rw',
    required => 1,
  );

  ....


  Foo->new(
    foo => [ Hello => [] ]
    bar => [
       [ "Content-Type" => "text/plain" ],
       [ "X-Zombies"    => "0"          ],
    ],
  );



=cut

=head1 TYPES

=head2 KeyWith

=head2 KeyWith[ X ]

A parameterizable type intended to simulate a singular key/value pair stored in an array.

The keys is required to be of type C<Str>, while the value is the parameterized type.

  KeyWith[ Foo ]

  ...

  [ "Key" => $fooitem ] # [ Str, Foo ]

=cut

sub x_KeyWith { ref($_[0]) eq 'ARRAY' && scalar @{$_[0]} == 2 }

my $KeyWith = Moose::Meta::TypeConstraint::Parameterizable->new(
    name               => 'KeyWith',
    package_defined_in => __PACKAGE__,
    parent             => Moose::Util::TypeConstraints::find_type_constraint('Ref'),
    constraint         => sub {
      return unless ref($_) eq 'ARRAY';
      return unless @{$_} == 2;
      return 1;
    },
    optimized_constraint => \&MooseX::Types::FakeHash::x_KeyWith,
    constraint_generator => sub {
      my $type_parameter = shift;
      my $check = $type_parameter->_compiled_type_constraint;
      my $keycheck = Moose::Util::TypeConstraints::find_type_constraint('Str')->_compiled_type_constraint;
      return sub {
         $keycheck->( $_->[0] ) || return;
         $check->( $_->[1] ) || return;
         1;
      }
    },
  );

Moose::Util::TypeConstraints::register_type_constraint( $KeyWith );
Moose::Util::TypeConstraints::add_parameterizable_type( $KeyWith );

sub type_storage {
  return { 'KeyWith' , 'KeyWith' }
}


1;
