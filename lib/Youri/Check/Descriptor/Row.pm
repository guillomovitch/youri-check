# $Id$
package Youri::Check::Descriptor::Row;

=head1 NAME

Youri::Check::Descriptor::Row - Result row descriptor

=head1 DESCRIPTION

This class describes how a result row is displayed.

=cut

use warnings;
use strict;
use Carp;

=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Check::Descriptor::Row object.

=cut

sub new {
    my $class = shift;

    my %options = (
        cells => undef,
        @_
    );

    my $self = bless {
        _cells => $options{cells},
    }, $class;

    return $self;
}

sub clone {
    my ($self) = @_;
    my $class = ref $self;
    croak "Not a class method" unless $class;

    return $class->new(
        cells => [ 
            map { $_->clone() } @{$self->{_cells}}
        ]
    );
}

sub drop_cell {
    my ($self, $name) = @_;
    croak "Not a class method" unless ref $self;

    my $found;
    for my $i (0 .. $#{$self->{_cells}}) {
        next unless $self->{_cells}->[$i]->get_name() eq $name;
        splice @{$self->{_cells}}, $i, 1;
        $found = 1;
        last;
    }

    warn "No such cell $name" unless $found;
}

sub get_cells {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;
    return @{$self->{_cells}};
}

sub get_mergeable_cells {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;
    return
        grep { $_->is_mergeable() }
        @{$self->{_cells}};
}

sub get_unmergeable_cells {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;
    return
        grep { ! $_->is_mergeable() }
        @{$self->{_cells}};
}


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
