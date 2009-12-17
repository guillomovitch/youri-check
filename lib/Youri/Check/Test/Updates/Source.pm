# $Id$
package Youri::Check::Test::Updates::Source;

=head1 NAME

Youri::Check::Test::Updates::Source - Abstract updates source

=head1 DESCRIPTION

This abstract class defines the updates source interface for
L<Youri::Check::Test::Updates> test plugin.

=cut

use Moose::Policy 'Moose::Policy::FollowPBP';
use Moose;
use MooseX::Types::Moose qw/Str HashRef/;
use Carp;

has 'id' => (
    is => 'rw',
    isa => Str
);

has 'aliases' => (
    is        => 'rw',
    isa       => HashRef[Str],
    predicate => 'has_aliases',
);

=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates object.

Generic parameters (subclasses may define additional ones):

=over

=item aliases $aliases

Hash of package aliases.

=back

Warning: do not call directly, call subclass constructor instead.

=cut

=head1 INSTANCE METHODS

Excepted explicit statement, package name is expressed with Mandriva naming
conventions.

=head2 get_package_version($package)

Returns available version for given package, which can be either a full
L<Youri::Package> object or just a package name.

=cut

sub get_package_version {
    my ($self, $package) = @_;
    croak "Not a class method" unless ref $self;

    my $name = ref $package && $package->isa('Youri::Package') ?
        $package->get_canonical_name() :
        $package;

    # translate in grabber namespace
    $name = $self->get_converted_package_name($name);

    # return if aliased to null 
    return unless $name;

    # otherwise return subclass computation
    return $self->_get_package_version($name);
}

=head2 get_package_url($package)

Returns the URL of information source for package with given name, which
can be either a full L<Youri::Package> object or just a package name.

=cut

sub get_package_url {
    my ($self, $package) = @_;
    croak "Not a class method" unless ref $self;

    my $name = ref $package && $package->isa('Youri::Package') ?
        $package->get_canonical_name() :
        $package;

    # retun subclass computation
    return $self->_get_package_url($self->get_converted_package_name($name));
}

=head2 get_converted_package_name($name)

Returns name converted to specific source naming conventions for package, which
can be either a full L<Youri::Package> object or just a package name.

=cut

sub get_converted_package_name {
    my ($self, $package) = @_;
    croak "Not a class method" unless ref $self;

    my $name = ref $package && $package->isa('Youri::Package') ?
        $package->get_canonical_name() :
        $package;

    # return alias if defined
    if ($self->has_aliases()) {
        my $alias = $self->get_aliases()->{$name};
        return $alias if $alias;
    }

    # otherwise return subclass computation
    return $self->_get_converted_package_name($name);
}

=head2 _get_package_version($name)

Hook called by default B<version()> implementation after name translation.

=cut

sub _get_package_version {
    my ($self, $name) = @_;
    return undef;
}

=head2 _get_package_url($name)

Hook called by default B<url()> implementation after name translation.

=cut

sub _get_package_url {
    my ($self, $name) = @_;
    return undef;
}

=head2 _get_converted_package_name($name)

Hook called by default B<name()> implementation if given name was not found in
the aliases.

=cut

sub _get_converted_package_name {
    my ($self, $name) = @_;
    return $name;
}

=head1 SUBCLASSING

The following methods have to be implemented:

=over

=item version

As an alternative, the B<_version()> hook can be implemented.

=item url

As an alternative, the <_url()> hook can be implemented.

=item name

As an alternative, the B<_name()> hook can be implemented.

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
