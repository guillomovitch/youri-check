# $Id$
package Youri::Check::Plugin::Report::File;

=head1 NAME

Youri::Check::Plugin::Report::File - Report results in files

=head1 DESCRIPTION

This plugin reports results in files. Additional subplugins handle specific
formats.

=cut

use warnings;
use strict;
use Carp;
use File::Path;
use Youri::Utils;
use base 'Youri::Check::Plugin::Report';

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

    $self->{_to}      = $options{to};
    $self->{_noclean} = $options{noclean};
    $self->{_noempty} = $options{noempty};

    foreach my $id (keys %{$options{formats}}) {
        print "Creating format $id\n" if $options{verbose};
        my $format_conf = $options{formats}->{$id};
        eval {
            push(
                @{$self->{_formats}},
                create_instance(
                    'Youri::Check::Plugin::Report::Format',
                    $format_conf,
                    {
                        id      => $id,
                        test    => $options{test},
                        verbose => $options{verbose},
                    }
                )
            );
        };
        carp "Failed to create format $id: $@\n" if $@;
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
    my ($self, $resultset, $type, $descriptor, $filter) = @_;

    my $iterator = $resultset->get_iterator(
        $type,
        [ 'source_package' ],
        $filter
    );

    $self->{_files}->{global}->{$type} = [
        $self->_report(
            $iterator,
            $descriptor,
            $type,
            "$type global report",
            "$self->{_to}",
        )
    ];
}

sub _individual_report {
    my ($self, $resultset, $type, $descriptor, $filter, $maintainer) = @_;

    my $iterator = $resultset->get_iterator(
        $type,
        [ 'source_package' ],
        {
            ($filter ? %$filter : () ),
            maintainer => [ $maintainer ]
        }
    );

    $self->{_files}->{maintainers}->{$maintainer}->{$type} = [
        $self->_report(
            $iterator,
            $descriptor,
            $type,
            "$type individual report for $maintainer",
            "$self->{_to}/$maintainer",
        )
    ];
}

sub _report {
    my ($self, $iterator, $descriptor, $type, $title, $path) = @_;

    return if $self->{_noempty} && ! $iterator->has_results();

    # initialisation
    foreach my $format (@{$self->{_formats}}) {
        $format->init_report(
            $title,
            $descriptor,
            $type
        );
    }

    # content creation
    my @results;
    while (my $result = $iterator->get_result()) {
        if (@results &&
            $result->{source_package} ne $results[0]->{source_package}
        ) {
            foreach my $format (@{$self->{_formats}}) {
                $format->add_results(\@results);
            }
            @results = ();
        }
        push(@results, $result);
    }

    my @extensions;
    my $now = DateTime->now(time_zone => 'local');
    my $footer = "Page generated the " . $now->ymd() . " at " . $now->hms();
    foreach my $format (@{$self->{_formats}}) {
        $format->add_results(\@results) if @results;

        $format->finish_report($footer);

        my $extension = $format->get_extension();

        $self->_write_file(
            $path,
            "$type.$extension",
            $format->get_content()
        );

        push(@extensions, $extension);
    }

    # return list of file formats created
    return @extensions;
}

sub _finish_report {
    my ($self, $types, $maintainers) = @_;

    my $now = DateTime->now(time_zone => 'local');
    my $footer = "Page generated the " . $now->ymd() . " at " . $now->hms();
    foreach my $format (@{$self->{_formats}}) {
        next unless $format->can('create_index');
        print "writing global index page\n" if $self->{_verbose};
        $format->create_index(
            "QA global report",
            $self->{_files}->{global},
            [ keys %{$self->{_files}->{maintainers}} ],
            $footer
        );

        my $extension = $format->get_extension();
        $self->_write_file(
            $self->{_to},
            "index.$extension",
            $format->get_content()
        );

        foreach my $maintainer (@$maintainers) {
            print "writing index page for $maintainer\n" if $self->{_verbose};
            $format->create_index(
                "QA report for $maintainer",
                $self->{_files}->{maintainers}->{$maintainer},
                undef,
                $footer
            );

            $self->_write_file(
                "$self->{_to}/$maintainer",
                "index.$extension",
                $format->get_content()
            );
        }
    }
}

sub _write_file {
    my ($self, $dir, $file, $content) = @_;

    if ($self->{_test}) {
        print STDOUT $$content;
    } else {
        mkpath($dir) unless -d $dir;
        my $path = "$dir/$file";
        open(my $out, '>', $path) or croak "Can't open file $path: $!";
        print $out $$content;
        close $out;
    }
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
