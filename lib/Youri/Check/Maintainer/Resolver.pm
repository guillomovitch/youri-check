# $Id$
package Youri::Check::Maintainer::Resolver;

=head1 NAME

Youri::Check::Maintainer::Resolver - Abstract maintainer resolver

=head1 DESCRIPTION

This abstract class defines Youri::Check::Maintainer::Resolver interface.

=head1 SYNOPSIS

    use Youri::Check::Maintainer::Resolver::Foo;

    my $resolver = Youri::Check::Maintainer::Resolver::Foo->new();

    print $resolver->get_maintainer('foo');

=cut

use Moose;
use MooseX::FollowPBP;
use Carp;
use MooseX::Types::Moose qw/Int/;

has 'verbosity'  => (is => 'rw', isa => Int,  default => 0);

=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Check::Maintainer::Resolver object.

No generic parameters (subclasses may define additional ones).

Warning: do not call directly, call subclass constructor instead.

=cut

=head2 get_maintainer($package)

Returns maintainer for given package, which can be either a full
L<Youri::Package> object or just a package name.

=head1 SUBCLASSING

The following methods have to be implemented:

=over

=item get_maintainer

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
