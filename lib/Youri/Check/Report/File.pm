# $Id: Text.pm 523 2005-10-11 08:36:49Z misc $
package Youri::Check::Report::File;

=head1 NAME

Youri::Check::Report::File - Report results in files

=head1 DESCRIPTION

This plugin reports results in files. Additional subplugins handle specific
formats.

=cut

use warnings;
use strict;
use Carp;
use File::Basename;
use File::Path;
use DateTime;
use Youri::Utils;
use base 'Youri::Check::Report';

sub _init {
    my $self = shift;
    my %options = (
        to      => '', # target directory
        noclean => 0,  # don't clean up target directory
        noempty => 0,  # don't generate empty reports
        formats => undef,
        @_
    );

    croak "no format defined" unless $options{formats};
    croak "formats should be an hashref" unless ref $options{formats} eq 'HASH';

    my $now = DateTime->now(time_zone => 'local');
    my $time = "the " . $now->ymd() . " at " . $now->hms();

    $self->{_to}      = $options{to};
    $self->{_noclean} = $options{noclean};
    $self->{_noempty} = $options{noempty};
    $self->{_time}    = $time;

    foreach my $id (keys %{$options{formats}}) {
        print "Creating format $id\n" if $options{verbose};
        eval {
            push(
                @{$self->{_formats}},
                create_instance(
                    'Youri::Check::Report::File::Format',
                    id        => $id,
                    test      => $options{test},
                    verbose   => $options{verbose},
                    %{$options{formats}->{$id}}
                )
            );
        };
        print STDERR "Failed to create format $id: $@\n" if $@;
    }

    croak "no formats created" unless @{$self->{_formats}};
}

sub _init_report {
    my ($self) = @_;

    # clean up output directory
    unless ($self->{_test} || $self->{_noclean} || !$self->{_to}) {
        my @files = glob($self->{_to} . '/*');
        rmtree(\@files) if @files;
    }
}

sub _global_report {
    my ($self, $resultset, $type, $descriptor) = @_;

    my $iterator = $resultset->get_iterator(
        $type,
        [ 'package' ]
    );

    $self->_report(
        $iterator,
        $descriptor,
        $type,
        "$type global report",
        "$self->{_to}",
        $self->{_files}->{global}
    );

}

sub _individual_report {
    my ($self, $resultset, $type, $descriptor, $maintainer) = @_;

    my $iterator = $resultset->get_iterator(
        $type,
        [ 'package' ],
        { maintainer => [ $maintainer ] }
    );

    $self->_report(
        $iterator,
        $descriptor,
        $type,
        "$type individual report for $maintainer",
        "$self->{_to}/$maintainer",
        $self->{_files}->{maintainers}->{$maintainer}
    );
}

sub _report {
    my ($self, $iterator, $descriptor, $type, $title, $path, $registry) = @_;

    return if $self->{_noempty} && ! $iterator->has_results();

    my @contents;

    # initialisation
    for my $i (0 .. $#{$self->{_formats}}) {
        $contents[$i] = $self->{_formats}->[$i]->get_header(
            $title,
            $descriptor,
        );
    }

    # content creation
    my @results;
    my $line = 0;
    while (my $result = $iterator->get_result()) {
        if (@results && $result->{package} ne $results[0]->{package}) {
            for my $i (0 .. $#{$self->{_formats}}) {
                $contents[$i] .= $self->{_formats}->[$i]->get_formated_row(
                    \@results,
                    $descriptor,
                    $line % 2 ? 'odd' : 'even',
                );
            }
            $line++;
            @results = ();
        }
        push(@results, $result);
    }

    # finalisation
    for my $i (0 .. $#{$self->{_formats}}) {
        if (@results) {
            # last results
            $contents[$i] .= $self->{_formats}->[$i]->get_formated_row(
                \@results,
                $descriptor,
                $line % 2 ? 'odd' : 'even',
            );
        }
        $contents[$i] .= $self->{_formats}->[$i]->get_footer(
            $self->{_time}
        );

        # create file
        my $extension = $self->{_formats}->[$i]->extension();
        $self->_write_file(
            "$path/$type.$extension",
            \$contents[$i]
        );

        # register file
        push(
            @{$registry->{$type}},
            $extension
        );
    }
}

sub _finish_report {
    my ($self, $types, $maintainers) = @_;

    foreach my $format (@{$self->{_formats}}) {
        next unless $format->can('get_index');
        my $extension = $format->extension();
        print STDERR "writing global index page\n" if $self->{_verbose};
        $self->_write_file(
            "$self->{_to}/index.$extension",
            $format->get_index(
                $self->{_time},
                "QA global report",
                $self->{_files}->{global},
                [ keys %{$self->{_files}->{maintainers}} ],
            )
        );
        foreach my $maintainer (@$maintainers) {
            print STDERR "writing index page for $maintainer\n" if $self->{_verbose};

            $self->_write_file(
                "$self->{_to}/$maintainer/index.$extension",
                $format->get_index(
                    $self->{_time},
                    "QA report for $maintainer",
                    $self->{_files}->{maintainers}->{$maintainer},
                    undef,
                )
            );
        }
    }
}

sub _write_file {
    my ($self, $file, $content) = @_;

    return unless $content;

    my $dirname = dirname($file);
    mkpath($dirname) unless -d $dirname;
    
    if ($self->{_test}) {
        *OUT = *STDOUT;
    } else {
        open(OUT, ">$file") or die "Can't open file $file: $!";
    }

    print OUT $$content;

    close(OUT) unless $self->{_test};
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
