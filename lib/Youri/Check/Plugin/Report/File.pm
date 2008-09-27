# $Id$
package Youri::Check::Plugin::Report::File;

=head1 NAME

Youri::Check::Plugin::Report::File - Report results in files

=head1 DESCRIPTION

This plugin reports results in files. Additional subplugins handle specific
formats.

=cut

use Moose::Policy 'Moose::Policy::FollowPBP';
use Moose;
use Moose::Util::TypeConstraints;
use Carp;
use File::Path;
use List::MoreUtils qw(all);
use Youri::Utils;
use Youri::Check::Types;

extends 'Youri::Check::Plugin::Report';

subtype 'HashRef[Youri::Check::Plugin::Report::File::Format]'
    => as 'HashRef'
    => where {
        all {
            blessed $_ &&
            $_->isa('Youri::Check::Plugin::Report::File::Format')
        } values %$_;
    };

subtype 'HashRef[HashRef]'
    => as 'HashRef'
    => where {
        all {
            ref($_) eq 'HASH'
        } values %$_;
    };
  
coerce 'HashRef[Youri::Check::Plugin::Report::File::Format]'
    => from 'HashRef[HashRef]'
        => via {
            my $in = $_;
            my $out;
            foreach my $key (keys %$in) {
            $out->{$key} = create_instance_from_configuration(
                    'Youri::Check::Plugin::Report::File::Format',
                    $in->{$key},
                    {id => $key}
                )
            }
            return $out;
        };

has 'database'    => (
    is => 'rw', isa => 'Youri::Check::Database'
);
has 'format' => (
    is       => 'rw',
    isa      => 'HashRef[Youri::Check::Plugin::Report::File::Format]',
    coerce   => 1,
    required => 1
);
has 'to' => (
    is       => 'rw',
    isa      => 'Directory',
    required => 1
);
has 'clean' => (
    is       => 'rw',
    isa      => 'Bool',
    default  => 1
);
has 'empty' => (
    is       => 'rw',
    isa      => 'Bool',
    default  => 1
);

sub init {
    my ($self) = @_;

    return if $self->is_test();
    return if !$self->get_clean();

    # clean up output directory
    my @files = glob($self->get_to() . '/*');
        rmtree(\@files) if @files;
}

sub run {
    my ($self) = @_;
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
