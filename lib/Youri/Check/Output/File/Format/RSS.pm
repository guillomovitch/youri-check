# $Id$
package Youri::Check::Output::File::Format::RSS;

=head1 NAME

Youri::Check::Output::File::Format::RSS - File RSS format support

=head1 DESCRIPTION

This format plugin for L<Youri::Check::Output::File> provides RSS format
support.

=cut

use warnings;
use strict;
use Carp;
use XML::RSS;
use base 'Youri::Check::Output::File::Format';

sub extension {
    return 'rss';
}

sub get_report {
    my ($self, $time, $title, $iterator, $type, $descriptor, $maintainer) = @_;

    return unless $maintainer;

    my $rss = XML::RSS->new(version => '2.0');
    $rss->channel(
        title       => $title,
        description => $title,
        language    => 'en',
        ttl         => 1440
    );
    
    my @cells_values =
        map { $_->get_value() }
        $descriptor->get_cells();

    while (my $result = $iterator->get_result()) {
        if ($type eq 'updates') {
            $rss->add_item(
                title       => "$result->{package} $result->{available} is available",
                description => "Current version is $result->{current}",
                link        => $result->{url} ?
                    $result->{url} : $result->{source},
                guid => "$result->{package}-$result->{available}"
            );
        } else {
            $rss->add_item(
                title       => "[$type] $result->{package}",
                description => join(
                    "\n",
                    (map { $result->{$_} || '' } @cells_values
                    )),
                link        => $result->{url},
                guid        => "$type-$result->{package}"
            );
        }
    }

    return \$rss->as_string();
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
