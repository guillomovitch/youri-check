# $Id$
package Youri::Check::Test;

=head1 NAME

Youri::Check::Test - Abstract test plugin

=head1 DESCRIPTION

This abstract class defines test plugin interface.

=cut

use warnings;
use strict;
use Carp;
use Youri::Utils;
use Youri::Check::Descriptor::Row;
use Youri::Check::Descriptor::Cell;
use base qw/Youri::Check::Plugin/;

use constant WARNING => 'warning';
use constant ERROR => 'error';

=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Check::Input object.

No generic parameters (subclasses may define additional ones).

Warning: do not call directly, call subclass constructor instead.

=cut

sub new {
    my $class = shift;
    croak "Abstract class" if $class eq __PACKAGE__;

    my %options = (
        id          => '',    # object id
        test        => 0,     # test mode
        verbose     => 0,     # verbose mode
        resolver    => undef, # maintainer resolver
        preferences => undef, # maintainer preferences
        @_
    );

    if ($options{resolver}) {
        croak "resolver should be a Youri::Check::Maintainer::Resolver object" unless $options{resolver}->isa("Youri::Check::Maintainer::Resolver");
    }
    if ($options{preferences}) {
        croak "preferences should be a Youri::Check::Maintainer::Preferences object" unless $options{preferences}->isa("Youri::Check::Maintainer::Preferences");
    }

    my $self = bless {
        _id          => $options{id},
        _test        => $options{test},
        _verbose     => $options{verbose},
        _resolver    => $options{resolver},
        _preferences => $options{preferences},
    }, $class;

    $self->_init(%options);

    return $self;
}

sub _init {
    # do nothing
}

=head1 INSTANCE METHODS

=head2 prepare(@medias)

Perform optional preliminary initialisation, using given list of
<Youri::Media> objects.

=cut

sub prepare {
    # do nothing
}

=head2 run($media, $resultset)

Check the packages from given L<Youri::Media> object, and store the
result in given L<Youri::Check::Resultset> object.

=head1 SUBCLASSING

The following methods have to be implemented:

=over

=item run

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
