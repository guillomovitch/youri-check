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
        _index => { map { $_->get_name() => 1 } @{$options{cells}} }
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

sub has_cell {
    my ($self, $name) = @_;
    croak "Not a class method" unless ref $self;
    return $self->{_index}->{$name};
}

sub drop_cell {
    my ($self, $name) = @_;
    croak "Not a class method" unless ref $self;

    if ($self->{_index}->{$name}) {
        delete $self->{_index}->{$name};
        $self->{_cells} = [
            grep { $_->get_name() ne $name }
            @{$self->{_cells}}
        ];
    } else {
        warn "No such cell $name";
    }
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
