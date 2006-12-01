# $Id$
package Youri::Check::Descriptor::Cell;

=head1 NAME

Youri::Check::Descriptor::Cell - Result cell descriptor

=head1 DESCRIPTION

This class describes how a result cell is displayed.

=cut

use warnings;
use strict;
use Carp;

=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Check::Descriptor::Cell object.

=cut

sub new {
    my $class = shift;

    my %options = (
        name        => '',
        description => '',
        type        => '',
        value       => '',
        link        => '',
        mergeable   => 0,
        @_
    );

    my $self = bless {
        _name        => $options{name},
        _description => $options{description},
        _type        => $options{type},
        _value       => $options{value},
        _link        => $options{link},
        _mergeable   => $options{mergeable},
    }, $class;

    return $self;
}

sub get_name {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;
    return $self->{_name};
}

sub get_description {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;
    return $self->{_description};
}

sub get_type {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;
    return $self->{_type};
}

sub get_value {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;
    return $self->{_value};
}

sub get_link {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;
    return $self->{_link};
}

sub is_mergeable {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;
    return $self->{_mergeable};
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
