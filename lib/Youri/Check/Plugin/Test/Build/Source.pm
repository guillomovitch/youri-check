# $Id$
package Youri::Check::Plugin::Test::Build::Source;

=head1 NAME

Youri::Check::Plugin::Test::Build::Source - Abstract build log source

=head1 DESCRIPTION

This abstract class defines the updates source interface for
L<Youri::Check::Plugin::Test::Build>.

=cut

use Moose::Policy 'Moose::Policy::FollowPBP';
use Moose;
use Carp;

has 'id' => (
    is => 'rw',
    isa => 'Str'
);

=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Check::Plugin::Test::Build object.

No generic parameters (subclasses may define additional ones).

Warning: do not call directly, call subclass constructor instead.

=cut

=head1 INSTANCE METHODS

=head2 fails($name, $version, $release, $arch, $media)

Returns true if build fails for package with given name, version and release, belonging to given media, on given architecture.

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
