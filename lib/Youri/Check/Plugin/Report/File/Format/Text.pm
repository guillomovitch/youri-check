# $Id$
package Youri::Check::Plugin::Report::File::Format::Text;

=head1 NAME

Youri::Check::Plugin::Report::File::Format::Text - Text format support for files

=head1 DESCRIPTION

This report format plugin provides text format support for files .

=cut

use warnings;
use strict;
use Carp;
use base 'Youri::Check::Plugin::Report::File::Format';

sub get_extension {
    return 'txt';
}

sub init_report {
    my ($self, $title, $descriptor, $type) = @_;
    croak "Not a class method" unless ref $self;

    $self->{_mergeable_cell_values} = [
        map { $_->get_value() }
        $descriptor->get_mergeable_cells()
    ];
    $self->{_unmergeable_cell_values} = [
        map { $_->get_value() }
        $descriptor->get_unmergeable_cells()
    ];

    $self->{_content} = "$title\n";
    $self->{_content} .= "\n";
    $self->{_content} .= join(
        "\t", map { $_->get_name() } $descriptor->get_cells()
    ) . "\n";
}

sub add_results {
    my ($self, $results) = @_;
    croak "Not a class method" unless ref $self;

    # first line contains merged cells
    $self->{_content} .= join(
        "\t",
        (map {
            $results->[0]->{$_} || ''
        } @{$self->{_mergeable_cell_values}}),
        (map {
            $results->[0]->{$_} || ''
        } @{$self->{_unmergeable_cell_values}})
    ) . "\n";
    # all lines contains other cells
    for my $i (1 .. $#$results) {
        $self->{_content} .= join(
            "\t",
            (map {
                ''
            } @{$self->{_mergeable_cell_values}}),
            (map {
                $results->[$i]->{$_} || ''
            } @{$self->{_unmergeable_cell_values}})
        ) . "\n";
    }

}

sub finish_report {
    my ($self, $footer) = @_;
    croak "Not a class method" unless ref $self;

    if ($footer) {
        $self->{_content} .= "\n";
        $self->{_content} .= "$footer\n";
    }
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
