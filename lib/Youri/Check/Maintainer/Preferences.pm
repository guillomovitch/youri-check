# $Id$
package Youri::Check::Maintainer::Preferences;

=head1 NAME

Youri::Check::Maintainer::Preferences - Abstract maintainer preferences

=head1 DESCRIPTION

This abstract class defines Youri::Check::Maintainer::Preferences interface.

=head1 SYNOPSIS

    use Youri::Check::Maintainer::Preferences::Foo;

    my $preferences = Youri::Check::Maintainer::Preferences::Foo->new();

=cut

use warnings;
use strict;
use Carp;

=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Check::Maintainer::Preferences object.

Warning: do not call directly, call subclass constructor instead.

=cut

sub new {
    my $class = shift;
    croak "Abstract class" if $class eq __PACKAGE__;

    my %options = (
        test    => 0,     # test mode
        verbose => 0,     # verbose mode
        @_
    );

    my $self = bless {
        _test    => $options{test},
        _verbose => $options{verbose},
    }, $class;

    $self->_init(%options);

    return $self;
}

sub _init {
    # do nothing
}

=head2 get_preference($maintainer, $plugin, $item)

Returns preference of given maintainer for given plugin and configuration item.

=head1 SUBCLASSING

The following methods have to be implemented:

=over

=item get

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
