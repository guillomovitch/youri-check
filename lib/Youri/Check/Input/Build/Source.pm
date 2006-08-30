# $Id$
package Youri::Check::Input::Build::Source;

=head1 NAME

Youri::Check::Input::Build::Source - Abstract build log source

=head1 DESCRIPTION

This abstract class defines the updates source interface for
L<Youri::Check::Input::Build>.

=cut

use warnings;
use strict;
use Carp;

=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Check::Input::Build object.

No generic parameters (subclasses may define additional ones).

Warning: do not call directly, call subclass constructor instead.

=cut

sub new {
    my $class = shift;
    croak "Abstract class" if $class eq __PACKAGE__;

    my %options = (
        id        => '',    # object id
        test      => 0,     # test mode
        verbose   => 0,     # verbose mode
        @_
    );

    my $self = bless {
        _id        => $options{id},
        _test      => $options{test},
        _verbose   => $options{verbose},
    }, $class;

    $self->_init(%options);

    return $self;
}

sub _init {
    # do nothing
}

=head1 INSTANCE METHODS

=head2 get_id()

Returns source identity.

=cut

sub get_id {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_id};
}

=head2 fails($name, $version, $release, $arch)

Returns true if build fails for package with given name, version and release on
given architecture.

=head2 status($name, $version, $release, $arch)

Returns exact build status for package with given name, version and release on
given architecture. It has to be called after fails().

=head2 url($name, $version, $release, $arch)

Returns URL of information source for package with given name, version and
release on given architecture. It has to be called after fails().

=head1 SUBCLASSING

The following methods have to be implemented:

=over

=item fails

=item status

=item url

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
