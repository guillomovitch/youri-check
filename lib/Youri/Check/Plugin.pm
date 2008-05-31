# $Id$
package Youri::Check::Plugin;

=head1 NAME

Youri::Check::Plugin - Abstract youri-check plugin

=head1 DESCRIPTION

This abstract class defines youri-check plugin interface.

=cut

use warnings;
use strict;
use Carp;

=head1 INSTANCE METHODS

=head2 get_id()

Returns plugin identity.

=cut

sub get_id {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_id};
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
