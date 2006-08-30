# $Id$
package Youri::Check::Maintainer::Resolver::Bugzilla;

=head1 NAME

Youri::Check::Maintainer::Resolver::Bugzilla - Bugzilla-based maintainer resolver

=head1 DESCRIPTION

This is a Bugzilla-based L<Youri::Check::Maintainer::Resolver> implementation.

It uses Bugzilla SQL database for resolving maintainers.

=cut

use warnings;
use strict;
use Carp;
use Youri::Bugzilla;
use base 'Youri::Check::Maintainer::Resolver';

=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Check::Maintainer::Resolver::Bugzilla object.

Specific parameters:

=over

=item host $host

Bugzilla database host.

=item base $base

Bugzilla database name.

=item user $user

Bugzilla database user.

=item pass $pass

Bugzilla database password.

=back

=cut

sub _init {
    my $self    = shift;
    my %options = (
        host => '', # host of the bug database
        base => '', # name of the bug database
        user => '', # user of the bug database
        pass => '', # pass of the bug database
        @_
    );

    croak "No host given" unless $options{host};
    croak "No base given" unless $options{base};
    croak "No user given" unless $options{user};
    croak "No pass given" unless $options{pass};

    my $bugzilla = Youri::Bugzilla->new(
        $options{host},
        $options{base},
        $options{user},
        $options{pass}
    );

    $self->{_bugzilla} = $bugzilla;
}

sub get_maintainer {
    my ($self, $package) = @_;
    croak "Not a class method" unless ref $self;

     my $name = ref $package && $package->isa('Youri::Package') ?
        $package->get_canonical_name() :
        $package;

    $self->{_maintainers}->{$name} =
        $self->{_bugzilla}->get_maintainer($name)
        unless exists $self->{_maintainers}->{$name};

    return $self->{_maintainers}->{$name};
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
