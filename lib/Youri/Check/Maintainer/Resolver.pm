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

use warnings;
use strict;
use Carp;
use Youri::Utils;

=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Check::Maintainer::Resolver object.

No generic parameters (subclasses may define additional ones).

Warning: do not call directly, call subclass constructor instead.

=cut

sub new {
    my $class = shift;
    croak "Abstract class" if $class eq __PACKAGE__;

    my %options = (
        test    => 0,  # test mode
        verbose => 0,  # verbose mode
        @_
    );

    my $self = bless {
        _test    => $options{test},
        _verbose => $options{verbose}
    }, $class;

    $self->_init(%options);

    return $self;
}

sub _init {
    # do nothing
}

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
