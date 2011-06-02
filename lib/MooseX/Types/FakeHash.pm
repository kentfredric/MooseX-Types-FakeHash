use strict;
use warnings;

package MooseX::Types::FakeHash;
BEGIN {
  $MooseX::Types::FakeHash::VERSION = '0.1.0';
}

# ABSTRACT: Types for emulating Hash-like behaviours with ArrayRefs.

use Moose::Meta::TypeConstraint::Parameterizable;
use MooseX::Types;
use Moose::Util::TypeConstraints ();



sub x_KeyWith  { ref( $_[0] ) eq 'ARRAY' && scalar @{ $_[0] } == 2 }
sub x_FakeHash { ref( $_[0] ) eq 'ARRAY' && !( scalar @{ $_[0] } & 1 ) }

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
      my $i = 0;
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

Moose::Util::TypeConstraints::register_type_constraint($_) for $KeyWith, $FakeHash;
Moose::Util::TypeConstraints::add_parameterizable_type($_) for $KeyWith, $FakeHash;

sub type_storage {
  return { map { ( $_ ) x 2 } qw( KeyWith FakeHash ) };
}

1;

__END__
=pod

=head1 NAME

MooseX::Types::FakeHash - Types for emulating Hash-like behaviours with ArrayRefs.

=head1 VERSION

version 0.1.0

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

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

