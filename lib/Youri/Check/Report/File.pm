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
use File::Path;
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

    $self->{_to}      = $options{to};
    $self->{_noclean} = $options{noclean};
    $self->{_noempty} = $options{noempty};

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

    $self->{_files}->{global} = $self->_report(
        $iterator,
        $descriptor,
        $type,
        "$type global report",
        "$self->{_to}",
    );

}

sub _individual_report {
    my ($self, $resultset, $type, $descriptor, $maintainer) = @_;

    my $iterator = $resultset->get_iterator(
        $type,
        [ 'package' ],
        { maintainer => [ $maintainer ] }
    );

    $self->{_files}->{maintainers}->{$maintainer} = $self->_report(
        $iterator,
        $descriptor,
        $type,
        "$type individual report for $maintainer",
        "$self->{_to}/$maintainer",
    );
}

sub _report {
    my ($self, $iterator, $descriptor, $type, $title, $path) = @_;

    return if $self->{_noempty} && ! $iterator->has_results();

    my @contents;
    my $files;

    # initialisation
    foreach my $format (@{$self->{_formats}}) {
        $format->init_report(
            $path,
            $type,
            $title,
            $descriptor,
        );
    }

    # content creation
    my @results;
    while (my $result = $iterator->get_result()) {
        if (@results && $result->{package} ne $results[0]->{package}) {
            foreach my $format (@{$self->{_formats}}) {
                $format->add_results(
                    \@results,
                    $descriptor,
                );
            }
            @results = ();
        }
        push(@results, $result);
    }

    # finalisation
    foreach my $format (@{$self->{_formats}}) {
        if (@results) {
            # last results
            $format->add_results(
                \@results,
                $descriptor,
            );
        }
        $format->finish_report();

        # register file
        push(
            @{$files->{$type}}, 
            $format->extension()
        );
    }

    return $files;
}

sub _finish_report {
    my ($self, $types, $maintainers) = @_;

    foreach my $format (@{$self->{_formats}}) {
        next unless $format->can('create_index');
        print STDERR "writing global index page\n" if $self->{_verbose};
        $format->create_index(
            $self->{_to},
            "QA global report",
            $self->{_files}->{global},
            [ keys %{$self->{_files}->{maintainers}} ],
        );

        foreach my $maintainer (@$maintainers) {
            print STDERR "writing index page for $maintainer\n" if $self->{_verbose};
            $format->create_index(
                "$self->{_to}/$maintainer",
                "QA report for $maintainer",
                $self->{_files}->{maintainers}->{$maintainer},
                undef
            );
        }
    }
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
