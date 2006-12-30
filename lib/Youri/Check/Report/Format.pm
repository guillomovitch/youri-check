# $Id$
package Youri::Check::Report::Format;

=head1 NAME

Youri::Check::Report::Format - Abstract format support

=head1 DESCRIPTION

This abstract class defines the format support interface for
L<Youri::Check::Report::File>.

=cut

use warnings;
use strict;
use Carp;

sub new {
    my $class = shift;
    croak "Abstract class" if $class eq __PACKAGE__;

    my %options = (
        id      => '',
        test    => 0,
        verbose => 0,
        @_
    );

    my $self = bless {
        _id         => $options{id},
        _test       => $options{test},
        _verbose    => $options{verbose},
    }, $class;

    $self->_init(%options);

    return $self;
}

sub _init {
    # do nothing
}

=head2 get_id()

Returns format handler identity.

=cut

sub get_id {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_id};
}

sub get_content {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return \$self->{_content};
}

sub init_report {
}

sub finish_report {
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
