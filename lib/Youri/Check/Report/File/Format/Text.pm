# $Id$
package Youri::Check::Report::File::Format::Text;

=head1 NAME

Youri::Check::Report::File::Format::Text - File text format support

=head1 DESCRIPTION

This format plugin for L<Youri::Check::Report::File> provides text format
support.

=cut

use warnings;
use strict;
use Carp;
use base 'Youri::Check::Report::File::Format';

sub extension {
    return 'txt';
}

sub get_header {
    my ($self, $title, $descriptor) = @_;

    my $header;
    $header .= $title;
    $header .= "\n";
    $header .=
        join("\t", map { $_->get_name() } $descriptor->get_cells()) .
        "\n";

    return $header;
}

sub get_footer {
    my ($self, $time) = @_;

    my $footer;
    $footer .= "\n";
    $footer .= "Page generated $time\n";

    return $footer;
}

sub get_formated_row {
    my ($self, $results, $descriptor, $class) = @_;

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
