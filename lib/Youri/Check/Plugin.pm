# $Id$
package Youri::Check::Plugin;

=head1 NAME

Youri::Check::Plugin - Abstract youri-check plugin

=head1 DESCRIPTION

This abstract class defines youri-check plugin interface.

=cut

use Moose::Policy 'Moose::Policy::FollowPBP';
use Moose;
use Carp;

has 'id'         => (is => 'ro', isa => 'Str');
has 'test'       => (is => 'rw', isa => 'Bool', reader => 'is_test');
has 'verbosity'  => (is => 'rw', isa => 'Int',  default => 0);

=head1 INSTANCE METHODS

=head2 get_id()

Returns plugin identity.

=cut

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
