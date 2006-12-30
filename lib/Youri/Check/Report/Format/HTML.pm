# $Id$
package Youri::Check::Report::Format::HTML;

=head1 NAME

Youri::Check::Report::Format::HTML - HTML format support

=head1 DESCRIPTION

This report format plugin provides HTML format support.

=cut

use warnings;
use strict;
use Carp;
use CGI qw/:standard *table *ul *Tr/;
use base 'Youri::Check::Report::Format';

my $extension = 'html';

sub get_extension {
    return $extension;
}

sub get_mime_type {
    return 'text/html';
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
}

sub init_report {
    my ($self, $title, $descriptor, $type) = @_;
    croak "Not a class method" unless ref $self;

    $self->{_count} = 0;
    $self->{_mergeable_cell_descriptors} =
        [ $descriptor->get_mergeable_cells() ];
    $self->{_unmergeable_cell_descriptors} =
        [ $descriptor->get_unmergeable_cells() ];

    $self->_init_page($title);

    $self->{_content} .= start_table();
    $self->{_content} .= Tr([
        th([ 
            map { $_->get_name() } $descriptor->get_cells()
        ])
    ]);
}


sub add_results {
    my ($self, $results) = @_;
    croak "Not a class method" unless ref $self;

    my $class = $self->{_count}++ % 2 ? 'odd' : 'even';

    for my $i (0 .. $#$results) {
        $self->{_content} .= start_Tr(
            { class => $class }
        );
        # first line contains merged cells
        if ($i == 0) {
            foreach my $cell_descriptor (
                @{$self->{_mergeable_cell_descriptors}}
            ) {
                $self->_add_cell(
                    $results->[$i],
                    $cell_descriptor,
                    { rowspan => scalar @$results }
                );
            }
        }
        # all lines contains other cells
        foreach my $cell_descriptor (
            @{$self->{_unmergeable_cell_descriptors}}
        ) {
            $self->_add_cell(
                $results->[$i],
                $cell_descriptor,
            );
        }
        $self->{_content} .= end_Tr();
    }
}

sub finish_report {
    my ($self, $footer) = @_;
    croak "Not a class method" unless ref $self;

    $self->{_content} .= end_table();

    $self->_finish_page($footer);
}

sub _add_cell {
    my ($self, $result, $cell_descriptor, $attributes) = @_;

    my $link = $cell_descriptor->get_link();
    if ($link && $result->{$link}) {
        $self->{_content} .= td(
            $attributes,
            a(
                { href => $result->{$link} },
                escapeHTML($result->{$cell_descriptor->get_value()})
            )
        );
    } else {
        $self->{_content} .= td(
            $attributes,
            escapeHTML($result->{$cell_descriptor->get_value()})
        );
    }
}

sub create_index {
    my ($self, $title, $reports, $maintainers, $footer) = @_;
    croak "Not a class method" unless ref $self;

    $self->_init_page($title);

    if ($reports) {
        $self->{_content} .= h2("Reports");
        my @types = keys %{$reports};

        $self->{_content} .= start_ul();
        foreach my $type (sort @types) {
            my $item;
            $item = a(
                { href => "$type.$extension" },
                $type
            );
            foreach my $other_extension (@{$reports->{$type}}) {
                next if ($other_extension eq $extension);
                $item .= " ".a(
                        { href => "$type.$other_extension" },
                        "[$other_extension]"
                );
            }
            $self->{_content} .= li($item);
        }
        $self->{_content} .= end_ul();
    }

    if ($maintainers) {
        $self->{_content} .= h2("Individual reports");

        $self->{_content} .= start_ul();
        foreach my $maintainer (sort @{$maintainers}) {
            $self->{_content} .= li(
                a(
                    { href => "$maintainer/index.html" },
                    _obfuscate($maintainer)
                )
            );
        }
        $self->{_content} .= end_ul();
    }

    $self->_finish_page($footer);
}

sub _init_page {
    my ($self, $title) = @_;

    $self->{_content} = start_html(
        -title => $title,
        -style => { code => $self->{_style} }
    );
    $self->{_content} .= h1($title);
}

sub _finish_page {
    my ($self, $footer) = @_;

    if ($footer) {
        $self->{_content} .= hr();
        $self->{_content} .= p({ class => 'footer' }, $footer);
    }
    $self->{_content} .= end_html();
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
