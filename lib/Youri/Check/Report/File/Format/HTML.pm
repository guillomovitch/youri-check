# $Id$
package Youri::Check::Report::File::Format::HTML;

=head1 NAME

Youri::Check::Report::File::Format::HTML - File HTML format support

=head1 DESCRIPTION

This format plugin for L<Youri::Check::Report::File> provides HTML format
support.

=cut

use warnings;
use strict;
use Carp;
use CGI;
use base 'Youri::Check::Report::File::Format';

sub extension {
    return 'html';
}

sub _init {
    my $self = shift;
    my %options = (
        style => <<EOF, # css style
h1 {
    text-align:center;
}
table {
    border-style:solid; 
    border-width:1px; 
    border-color:black;
    width:100%;
}
tr.odd { 
    background-color:white;
}
tr.even { 
    background-color:silver;
}
p.footer {
    font-size:smaller;
    text-align:center;
}
EOF
        @_
    );

    $self->{_style} = $options{style};
    $self->{_cgi}   = CGI->new();
}

sub get_report {
    my ($self, $time, $title, $iterator, $type, $descriptor, $maintainer) = @_;

    my $content;
    $content .= $self->{_cgi}->start_table();
    $content .= $self->{_cgi}->Tr([
        $self->{_cgi}->th([ 
            map { $_->get_name() } $descriptor->get_cells()
        ])
    ]);

    # merge all results related to a single package into a single row
    my @results;
    my $line;
    while (my $result = $iterator->get_result()) {
        if (@results && $result->{package} ne $results[0]->{package}) {
            $content .= $self->_get_formated_row(
                \@results,
                $descriptor,
                $line++ % 2 ? 'odd' : 'even',
            );
            @results = ();
        }
        push(@results, $result);
    }
    $content .= $self->_get_formated_row(
        \@results,
        $descriptor,
        $line++ % 2 ? 'odd' : 'even'
    );
    $content .= $self->{_cgi}->end_table();

    return $self->_get_html_page($time, $title, \$content);
}

sub get_index {
    my ($self, $time, $title, $reports, $maintainers) = @_;

    my $content;

    if ($reports) {
        $content .= $self->{_cgi}->h2("Reports");
        my @types = keys %{$reports};

        $content .= $self->{_cgi}->start_ul();
        foreach my $type (sort @types) {
            my $item;
            $item = $self->{_cgi}->a(
                { href => "$type.html" },
                $type
            );
            foreach my $extension (@{$reports->{$type}}) {
                next if ($extension eq extension());
                $item .= " ".$self->{_cgi}->a(
                        { href => "$type.$extension" },
                        "[$extension]"
                );
            }
            $content .= $self->{_cgi}->li($item);
        }
        $content .= $self->{_cgi}->end_ul();
    }

    if ($maintainers) {
        $content .= $self->{_cgi}->h2("Individual reports");

        $content .= $self->{_cgi}->start_ul();
        foreach my $maintainer (sort @{$maintainers}) {
            $content .= $self->{_cgi}->li(
                $self->{_cgi}->a(
                    { href => "$maintainer/index.html" },
                    _obfuscate($maintainer)
                )
            );
        }
        $content .= $self->{_cgi}->end_ul();
    }

    return $self->_get_html_page($time, $title, \$content);
}

sub _get_formated_row {
    my ($self, $results, $descriptor, $class) = @_;

    my $row;
    my @mergeable_cells = $descriptor->get_mergeable_cells();
    my @unmergeable_cells = $descriptor->get_unmergeable_cells();

    for my $i (0 .. $#$results) {
        $row .= $self->{_cgi}->start_Tr(
            { class => $class }
        );
        # first line contains merged cells
        if ($i == 0) {
            foreach my $cell (@mergeable_cells) {
                $row .= $self->_get_formated_cell(
                    $results->[$i],
                    $cell,
                    { rowspan => scalar @$results }
                );
            }
        }
        # all lines contains other cells
        foreach my $cell (@unmergeable_cells) {
            $row .= $self->_get_formated_cell(
                $results->[$i],
                $cell,
            );
        }
        $row .= $self->{_cgi}->end_Tr();
    }

    return $row;
}

sub _get_formated_cell {
    my ($self, $result, $descriptor, $attributes) = @_;

    my $cell;
    my $link = $descriptor->get_link();
    if ($link && $result->{$link}) {
        $cell = $self->{_cgi}->td(
            $attributes,
            $self->{_cgi}->a(
                { href => $result->{$link} },
                $self->{_cgi}->escapeHTML($result->{$descriptor->get_value()})
            )
        );
    } else {
        $cell = $self->{_cgi}->td(
            $attributes,
            $self->{_cgi}->escapeHTML($result->{$descriptor->get_value()})
        );
    }

    return $cell;
}

sub _get_html_page {
    my ($self, $time, $title, $body) = @_;

    my $content;
    $content .= $self->{_cgi}->start_html(
        -title => $title,
        -style => { code => $self->{_style} }
    );
    $content .= $self->{_cgi}->h1($title);
    $content .= $$body;
    $content .= $self->{_cgi}->hr();
    $content .= $self->{_cgi}->p(
        { class => 'footer' },
        "Page generated $time"
    );
    $content .= $self->{_cgi}->end_html();

    return \$content;
}

sub _obfuscate {
    my ($email) = @_;

    return unless $email;

    $email =~ s/\@/ at /;
    $email =~ s/\./ dot /;

    return $email;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
