use strict;
use warnings;

package MooseX::Types::FakeHash;

# ABSTRACT: Types for emulating Hash-like behaviours with ArrayRefs.

use MooseX::Types;
use Moose::Util::TypeConstraints ();
use Moose::Meta::TypeConstraint::Parameterizable;
use Moose::Meta::TypeConstraint::Parameterized;

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


  has bar ( isa => KeyWith[ Foo ] , ... );

  ...

  ->new(
    bar => [ "Key" => $fooitem ] # [ Str, Foo ]
  );

=cut

sub x_KeyWith  { ref( $_[0] ) eq 'ARRAY' && scalar @{ $_[0] } == 2 }
sub x_FakeHash { ref( $_[0] ) eq 'ARRAY' && !( scalar @{ $_[0] } & 1 ) }
sub x_OrderedFakeHash { ref( $_[0] ) eq 'ARRAY' }

my $KeyWith = Moose::Meta::TypeConstraint::Parameterizable->new(
  name               => 'KeyWith',
  package_defined_in => __PACKAGE__,
  parent             => Moose::Util::TypeConstraints::find_type_constraint('Ref'),
  constraint         => sub {
    return unless ref($_) eq 'ARRAY';    # its an array
    return unless @{$_} == 2;            # and it has exactly 2 keys.
    return 1;
  },
  optimized_constraint => \&MooseX::Types::FakeHash::x_KeyWith,
  constraint_generator => sub {
    my $type_parameter = shift;
    my $check          = $type_parameter->_compiled_type_constraint;
    my $keycheck       = Moose::Util::TypeConstraints::find_type_constraint('Str')->_compiled_type_constraint;
    return sub {
      $keycheck->( $_->[0] ) || return;
      $check->( $_->[1] )    || return;
      1;
    };
  },
);

Moose::Util::TypeConstraints::register_type_constraint($KeyWith);
Moose::Util::TypeConstraints::add_parameterizable_type($KeyWith);

=head2 FakeHash

=head2 FakeHash[ X ]

A parameterizable type intended to simulate the values of a HashRef, but stored in an ArrayRef instead
as an even number of key/values.

The keys are required to be of type C<Str>, while the value is the parameterized type.

  has bar ( isa => FakeHash[ Foo ] , ... );

  ...

  ->new(
    bar => [
      "Key"           => $fooitem,
      "AnotherKey"    => $baritem,
      "YetAnotherKey" => $quuxitem,
    ] # [ Str, Foo, Str, Foo, Str, Foo ]
  );

=cut

my $FakeHash = Moose::Meta::TypeConstraint::Parameterizable->new(
  name               => 'FakeHash',
  package_defined_in => __PACKAGE__,
  parent             => Moose::Util::TypeConstraints::find_type_constraint('Ref'),
  constraint         => sub {
    return unless ref($_) eq 'ARRAY';    # its an array
    return unless !( scalar @{$_} & 1 ); # and it has a multiple of 2 keys ( bitwise checks for even, 0 == true )
    return 1;
  },
  optimized_constraint => \&MooseX::Types::FakeHash::x_FakeHash,
  constraint_generator => sub {
    my $type_parameter = shift;
    my $check          = $type_parameter->_compiled_type_constraint;
    my $keycheck       = Moose::Util::TypeConstraints::find_type_constraint('Str')->_compiled_type_constraint;
    return sub {
      my @items = @{$_};
      my $i     = 0;
      while ( $i <= $#items ) {
        $keycheck->( $items[$i] ) || return;
        $check->( $items[ $i + 1 ] ) || return;
      }
      continue {
        $i += 2;
      }

      1;
    };
  },
);

Moose::Util::TypeConstraints::register_type_constraint($FakeHash);
Moose::Util::TypeConstraints::add_parameterizable_type($FakeHash);

=head2 OrderedFakeHash

=head2 OrderedFakeHash[ X ]

A parameterizable type intended to simulate the values of a HashRef, but stored in an ArrayRef instead
as an array of L</KeyWith> items. This is much like a L</FakeHash>, but slightly different, in that the paring of the Key/Value is stricter,
and numerical-offset based lookup is simpler.

  [
     [ "Key" => $value ],
     [ "Key" => $value ],
  ]

In essence, OrderedFakeHash[ x ] is ShortHand for ArrayRef[ KeyWith[ x ] ].

This makes it harder to convert to a native Perl 5 Hash, but somewhat easier to iterate pairwise.

  my $data = $object->orderedfakehashthing();
  for my $pair ( @($data) ){
    my ( $key, $value ) = @{ $pair };
    ....
  }

The keys are required to be of type C<Str>, while the value is the parameterized type.

  has bar ( isa => OrderedFakeHash[ Foo ] , ... );

  ...

  ->new(
    bar => [
      [ "Key"           => $fooitem  ],
      [ "AnotherKey"    => $baritem  ],
      [ "YetAnotherKey" => $quuxitem ],
    ] # [ [ Str, Foo ],[ Str, Foo ],[ Str, Foo ] ]
  );

=cut

my $OrderedFakeHash = Moose::Meta::TypeConstraint::Parameterizable->new(
  name               => 'OrderedFakeHash',
  package_defined_in => __PACKAGE__,
  parent             => Moose::Util::TypeConstraints::find_type_constraint('Ref'),
  constraint         => sub {
    return unless ref($_) eq 'ARRAY';    # its an array
    return 1;
  },
  optimized_constraint => \&MooseX::Types::FakeHash::x_OrderedFakeHash,
  constraint_generator => sub {
    my $type_parameter = shift;
    my $subtype        = Moose::Meta::TypeConstraint::Parameterized->new(
      name           => 'OrderedFakeHash::KeyWith[' . $type_parameter->name . ']',
      parent         => $KeyWith,
      type_parameter => $type_parameter,
    );
    return sub {
      for my $pair ( @{$_} ) {
        $subtype->assert_valid($pair) || return;
      }
      1;
    };
  },
);

Moose::Util::TypeConstraints::register_type_constraint($OrderedFakeHash);
Moose::Util::TypeConstraints::add_parameterizable_type($OrderedFakeHash);

sub type_storage {
  return { map { ($_) x 2 } qw( KeyWith FakeHash OrderedFakeHash ) };
}

1;
