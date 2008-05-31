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

=head2 clone()

Creates and returns a clone from this descriptor.

=cut

sub clone {
    my ($self) = @_;
    my $class = ref $self;
    croak "Not a class method" unless $class;

    return $class->new(
        name        => $self->{_name},
        description => $self->{_description},
        mergeable   => $self->{_mergeable},
        value       => $self->{_value},
        type        => $self->{_type},
        link        => $self->{_link}
    );
}

=head2 get_name()

Returns the name of this cell.

=cut

sub get_name {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;
    return $self->{_name};
}

=head2 get_description()

Returns the description of this cell.

=cut

sub get_description {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;
    return $self->{_description};
}

=head2 get_type()

Returns the type of this cell.

=cut

sub get_type {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;
    return $self->{_type};
}

=head2 get_value()

Returns the raw value of this cell.

=cut

sub get_value {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;
    return $self->{_value};
}

=head2 get_link()

Returns the link value of this cell.

=cut

sub get_link {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;
    return $self->{_link};
}

=head2 is_mergeable()

Tells if this cell is mergeable.

=cut

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
