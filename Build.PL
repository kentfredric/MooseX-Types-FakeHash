
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Moose' => '0',
    'MooseX::Types::Moose' => '0',
    'Test::Fatal' => '0',
    'Test::More' => '0.96'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Types for emulating Hash-like behaviours with ArrayRefs.',
  'dist_author' => [
    'Kent Fredric <kentnl@cpan.org>'
  ],
  'dist_name' => 'MooseX-Types-FakeHash',
  'dist_version' => '0.1.0',
  'license' => 'perl',
  'module_name' => 'MooseX::Types::FakeHash',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Moose::Meta::TypeConstraint::Parameterizable' => '0',
    'Moose::Meta::TypeConstraint::Parameterized' => '0',
    'Moose::Util::TypeConstraints' => '0',
    'MooseX::Types' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
