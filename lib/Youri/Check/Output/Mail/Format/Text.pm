# $Id: Mail.pm 580 2006-01-11 22:59:36Z guillomovitch $
package Youri::Check::Output::Mail::Format::Text;

=head1 NAME

Youri::Check::Output::Mail::Format::Text - Mail text format support

=head1 DESCRIPTION

This format plugin for L<Youri::Check::Output::Mail> provides text format
support.

=cut

use warnings;
use strict;
use Carp;
use base 'Youri::Check::Output::Mail::Format';

sub type {
    return 'text/plain';
}

sub get_report {
    my ($self, $time, $title, $iterator, $type, $descriptor, $maintainer) = @_;

    my $content;
    $content .= $title;
    $content .= "\n";
    $content .=
        join("\t", map { $_->get_name() } $descriptor->get_cells()) .
        "\n";

    # merge all results related to a single package into a single row
    my @results;
    while (my $result = $iterator->get_result()) {
        if (@results && $result->{package} ne $results[0]->{package}) {
            $content .= $self->_get_formated_row(
                \@results,
                $descriptor,
            );
            @results = ();
        }
        push(@results, $result);
    }
    $content .= $self->_get_formated_row(
        \@results,
        $descriptor,
    );

    return \$content;
}

sub _get_formated_row {
    my ($self, $results, $descriptor) = @_;

    my $row;
    my @mergeable_cells_values =
        map { $_->get_value() }
        $descriptor->get_mergeable_cells();
    my @unmergeable_cells_values =
        map { $_->get_value() }
        $descriptor->get_unmergeable_cells();

    # first line contains merged cells
    $row .= join(
        "\t",
        (map { $results->[0]->{$_} || '' } @mergeable_cells_values),
        (map { $results->[0]->{$_} || '' } @unmergeable_cells_values)
    ) . "\n";
    # all lines contains other cells
    for my $i (1 .. $#$results) {
        $row .= join(
            "\t",
            (map { '' } @mergeable_cells_values),
            (map { $results->[$i]->{$_} || '' } @unmergeable_cells_values)
        ) . "\n";
    }

    return $row;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
