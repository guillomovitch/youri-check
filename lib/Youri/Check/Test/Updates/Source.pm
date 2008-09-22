# $Id$
package Youri::Check::Test::Updates::Source;

=head1 NAME

Youri::Check::Test::Updates::Source - Abstract updates source

=head1 DESCRIPTION

This abstract class defines the updates source interface for
L<Youri::Check::Test::Updates>.

=cut

use Moose::Policy 'Moose::Policy::FollowPBP';
use Moose;
use Carp;

has 'id' => (
    is => 'rw',
    isa => 'Str'
);

has 'aliases' => (
    is => 'rw',
    isa => 'HashRef[Str]'
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

=head2 get_version($package)

Returns available version for given package, which can be either a full
L<Youri::Package> object or just a package name.

=cut

sub get_version {
    my ($self, $package) = @_;
    croak "Not a class method" unless ref $self;

    my $name = ref $package && $package->isa('Youri::Package') ?
        $package->get_canonical_name() :
        $package;

    # translate in grabber namespace
    $name = $self->get_name($name);

    # return if aliased to null 
    return unless $name;

    # return subclass computation
    return $self->_version($name);
}

=head2 get_url($name)

Returns the URL of information source for package with given name.

=cut

sub get_url {
    my ($self, $name) = @_;

    # retun subclass computation
    return $self->_url($self->get_name($name));
}

=head2 get_name($name)

Returns name converted to specific source naming conventions for package with given name.

=cut

sub get_name {
    my ($self, $name) = @_;
    croak "Not a class method" unless ref $self;

    # return config aliases if it exists
    if ($self->{_aliases} ) {
        return $self->{_aliases}->{$name} if exists $self->{_aliases}->{$name};
    }

    # return maintainer aliases if it exists
    if ($self->{_resolver} && $self->{_preferences}) {
        my $maintainer = $self->{_resolver}->get_maintainer($name);
        if ($maintainer) {
            my $aliases = $self->{_preferences}->get_preference(
                $maintainer,
                $self->{_check_id},
                'aliases'
            );
            if ($aliases) {
                if ($aliases->{all}) {
                    return $aliases->{all}->{$name} if exists $aliases->{all}->{$name};
                }
                if ($aliases->{$self->{_id}}) {
                    return $aliases->{$self->{_id}}->{$name} if exists $aliases->{$self->{_id}}->{$name};
                }
            }
        }
    }

    # return return subclass computation
    return $self->_name($name);
}

=head2 _version($name)

Hook called by default B<version()> implementation after name translation.

=cut

sub _version {
    my ($self, $name) = @_;
    return $self->{_versions}->{$name};
}

=head2 _url($name)

Hook called by default B<url()> implementation after name translation.

=cut

sub _url {
    my ($self, $name) = @_;
    return;
}

=head2 _name($name)

Hook called by default B<name()> implementation if given name was not found in
the aliases.

=cut

sub _name {
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
