use strict;
use warnings;

package MooseX::Types::FakeHash;

# ABSTRACT: Types for emulating Hash-like behaviours with ArrayRefs.

use Moose::Meta::TypeConstraint::Parameterizable;
use MooseX::Types;
use Moose::Util::TypeConstraints ();

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
