# $Id: Base.pm 483 2005-08-01 21:39:05Z guillomovitch $
package Youri::Check::Resultset;

=head1 NAME

Youri::Check::Resultset - Abstract resultset

=head1 DESCRIPTION

This abstract class defines Youri::Check::Resultset interface

=cut

use warnings;
use strict;
use Carp;
use Scalar::Util qw/blessed/;
use Youri::Utils;

=head1 CLASS METHODS

=head2 new(%hash)

Creates and returns a new Youri::Check::Resultset object.

No generic parameters (subclasses may define additional ones).

Warning: do not call directly, call subclass constructor instead.

=cut

sub new {
    my $class   = shift;
    my %options = (
        test     => 0,     # test mode
        verbose  => 0,     # verbose mode
        resolver => undef,  # maintainer resolver, 
        @_
    );

    croak "Abstract class" if $class eq __PACKAGE__;

    my $self = bless {
        _test     => $options{test},
        _verbose  => $options{verbose},
        _resolver => $options{resolver},
    }, $class;

    $self->_init(%options);

    return $self;
}

sub _init {
    # do nothing
}

=head1 INSTANCE METHODS

=head2 set_resolver()

Set L<Youri::Check::Maintainer::Resolver> object used to resolve package
maintainers.

=cut

sub set_resolver {
    my ($self, $resolver) = @_;
    croak "Not a class method" unless ref $self;

    croak "resolver should be a Youri::Check::Maintainer::Resolver object"
        unless blessed $resolver &&
        $resolver->isa("Youri::Check::Maintainer::Resolver");

    $self->{_resolver} = $resolver;
}

=head2 clone()

Clone resultset object.

=head2 reset()

Reset resultset object, by deleting all contained results.

=head2 add_result($type, $media, $package, $values)

Add given hash reference as a new result for given type and L<Youri::Package> object.

=head2 get_maintainers()

Returns the list of all maintainers with results.

=head2 get_iterator($id, $sort, $filter)

Returns a L<Youri::Check::Resultset::Iterator> object over results for given input it, with optional sort and filter directives.

sort must be an arrayref of column names, such as [ 'package' ].

filter must be a hashref of arrayref of acceptables values indexed by column names, such as { level => [ 'warning', 'error'] }.

=head1 SUBCLASSING

All instances methods have to be implemented.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
