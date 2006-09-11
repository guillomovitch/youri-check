# $Id$
package Youri::Check::Report::File::Format::RSS;

=head1 NAME

Youri::Check::Report::File::Format::RSS - File RSS format support

=head1 DESCRIPTION

This format plugin for L<Youri::Check::Report::File> provides RSS format
support.

=cut

use warnings;
use strict;
use Carp;
use XML::RSS;
use base 'Youri::Check::Report::File::Format';

sub extension {
    return 'rss';
}

sub init_report {
    my ($self, $path, $type, $title, $descriptor) = @_;

    my $rss = XML::RSS->new(version => '2.0');
    $rss->channel(
        title       => $title,
        description => $title,
        language    => 'en',
        ttl         => 1440
    );

    $self->{_rss} = $rss;
    $self->{_type} = $type;
    $self->open_output($path, $type . '.rss');
}

sub add_results {
    my ($self, $results, $descriptor) = @_;
    
    my @cells_values =
        map { $_->get_value() }
        $descriptor->get_cells();

    foreach my $result (@{$results}) {
        if ($self->{_type} eq 'updates') {
            $self->{_rss}->add_item(
                title       => "$result->{package} $result->{available} is available",
                description => "Current version is $result->{current}",
                link        => $result->{url} ?
                    $result->{url} : $result->{source},
                guid => "$result->{package}-$result->{available}"
            );
        } else {
            $self->{_rss}->add_item(
                title       => "[$self->{_type}] $result->{package}",
                description => join(
                    "\n",
                    (map { $result->{$_} || '' } @cells_values
                    )),
                link        => $result->{url},
                guid        => "$self->{_type}-$result->{package}"
            );
        }
    }

}

sub finish_report {
    my ($self) = @_;

    $self->{_out}->print($self->{_rss}->as_string());
    $self->close_output();
}


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
