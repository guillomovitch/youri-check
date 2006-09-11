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

sub init_report {
    my ($self, $path, $type, $title, $descriptor) = @_;

    $self->{_count} = 0;
    $self->_init_page($path, $type . '.html', $title);

    $self->{_out}->print($self->{_cgi}->start_table());
    $self->{_out}->print(
        $self->{_cgi}->Tr([
            $self->{_cgi}->th([ 
                map { $_->get_name() } $descriptor->get_cells()
            ])
        ])
    );
}

sub finish_report {
    my ($self) = @_;

    $self->{_out}->print($self->{_cgi}->end_table());

    $self->_finish_page();
}

sub add_results {
    my ($self, $results, $descriptor) = @_;

    my $class = $self->{_count}++ % 2 ? 'odd' : 'even';
    my @mergeable_cells = $descriptor->get_mergeable_cells();
    my @unmergeable_cells = $descriptor->get_unmergeable_cells();

    for my $i (0 .. $#$results) {
        $self->{_out}->print($self->{_cgi}->start_Tr(
            { class => $class }
        ));
        # first line contains merged cells
        if ($i == 0) {
            foreach my $cell (@mergeable_cells) {
                $self->_add_cell(
                    $results->[$i],
                    $cell,
                    { rowspan => scalar @$results }
                );
            }
        }
        # all lines contains other cells
        foreach my $cell (@unmergeable_cells) {
            $self->_add_cell(
                $results->[$i],
                $cell,
            );
        }
        $self->{_out}->print($self->{_cgi}->end_Tr());
    }
}

sub _add_cell {
    my ($self, $result, $descriptor, $attributes) = @_;

    my $link = $descriptor->get_link();
    if ($link && $result->{$link}) {
        $self->{_out}->print($self->{_cgi}->td(
            $attributes,
            $self->{_cgi}->a(
                { href => $result->{$link} },
                $self->{_cgi}->escapeHTML($result->{$descriptor->get_value()})
            )
        ));
    } else {
        $self->{_out}->print($self->{_cgi}->td(
            $attributes,
            $self->{_cgi}->escapeHTML($result->{$descriptor->get_value()})
        ));
    }
}

sub create_index {
    my ($self, $path, $title, $reports, $maintainers) = @_;

    $self->_init_page($path, 'index.html', $title);

    if ($reports) {
        $self->{_out}->print($self->{_cgi}->h2("Reports"));
        my @types = keys %{$reports};

        $self->{_out}->print($self->{_cgi}->start_ul());
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
            $self->{_out}->print($self->{_cgi}->li($item));
        }
        $self->{_out}->print($self->{_cgi}->end_ul());
    }

    if ($maintainers) {
        $self->{_out}->print($self->{_cgi}->h2("Individual reports"));

        $self->{_out}->print($self->{_cgi}->start_ul());
        foreach my $maintainer (sort @{$maintainers}) {
            $self->{_out}->print($self->{_cgi}->li(
                $self->{_cgi}->a(
                    { href => "$maintainer/index.html" },
                    _obfuscate($maintainer)
                )
            ));
        }
        $self->{_out}->print($self->{_cgi}->end_ul());
    }

    $self->_finish_page();
}

sub _init_page {
    my ($self, $path, $name, $title) = @_;

    $self->open_output($path, $name);

    $self->{out}->print($self->{_cgi}->start_html(
        -title => $title,
        -style => { code => $self->{_style} }
    ));
    $self->{out}->print($self->{_cgi}->h1($title));
}

sub _finish_page {
    my ($self) = @_;

    $self->{out}->print($self->{_cgi}->hr());
    $self->{out}->print($self->{_cgi}->p(
        { class => 'footer' },
        "Page generated $self->{_time}"
    ));
    $self->{out}->print($self->{_cgi}->end_html());

    $self->close_output();
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
