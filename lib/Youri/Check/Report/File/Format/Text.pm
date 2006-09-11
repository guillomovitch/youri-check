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

sub init_report {
    my ($self, $path, $type, $title, $descriptor) = @_;

    $self->open_output($path, $type . '.txt');

    $self->{_out}->print("$title\n");
    $self->{_out}->print("\n");
    $self->{_out}->print(
        join("\t", map { $_->get_name() } $descriptor->get_cells()) .  "\n"
    );
}

sub finish_report {
    my ($self) = @_;

    $self->{_out}->print("\n");
    $self->{_out}->print("Page generated $self->{_time}\n");

    $self->close_output();
}

sub add_results {
    my ($self, $results, $descriptor) = @_;

    my @mergeable_cells_values =
        map { $_->get_value() }
        $descriptor->get_mergeable_cells();
    my @unmergeable_cells_values =
        map { $_->get_value() }
        $descriptor->get_unmergeable_cells();

    # first line contains merged cells
    $self->{_out}->print(join(
        "\t",
        (map { $results->[0]->{$_} || '' } @mergeable_cells_values),
        (map { $results->[0]->{$_} || '' } @unmergeable_cells_values)
    ) . "\n");
    # all lines contains other cells
    for my $i (1 .. $#$results) {
        $self->{_out}->print(join(
            "\t",
            (map { '' } @mergeable_cells_values),
            (map { $results->[$i]->{$_} || '' } @unmergeable_cells_values)
        ) . "\n");
    }

}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
