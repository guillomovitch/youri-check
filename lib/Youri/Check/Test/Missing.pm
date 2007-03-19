package Youri::Check::Test::Missing;

=head1 NAME

Youri::Check::Test::Missing - Check components consistency

=head1 DESCRIPTION

This plugin checks consistency between package components, and report outdated
ones.

=cut

use warnings;
use strict;
use Carp;
use List::MoreUtils qw/all any/;
use base 'Youri::Check::Test';

my $descriptor = Youri::Check::Descriptor::Row->new(
    cells => [
        Youri::Check::Descriptor::Cell->new(
            name        => 'source package',
            description => 'source package',
            mergeable   => 1,
            value       => 'source_package',
            type        => 'string',
        ),
        Youri::Check::Descriptor::Cell->new(
            name        => 'maintainer',
            description => 'maintainer',
            mergeable   => 1,
            value       => 'maintainer',
            type        => 'email',
        ),
        Youri::Check::Descriptor::Cell->new(
            name        => 'package',
            description => 'distribution unit',
            mergeable   => 0,
            value       => 'package',
            type        => 'string',
        ),
        Youri::Check::Descriptor::Cell->new(
            name        => 'architecture',
            description => 'architecture',
            mergeable   => 0,
            value       => 'arch',
            type        => 'string',
        ),
        Youri::Check::Descriptor::Cell->new(
            name        => 'revision',
            description => 'revision',
            mergeable   => 0,
            value       => 'revision',
            type        => 'string',
        ),
        Youri::Check::Descriptor::Cell->new(
            name        => 'error',
            description => 'error',
            mergeable   => 0,
            value       => 'error',
            type        => 'string',
        ),
    ]
);

sub get_descriptor {
    return $descriptor;
}

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Missing object.

No specific parameters.

=cut

sub prepare {
    my ($self, @medias)  = @_;
    croak "Not a class method" unless ref $self;
    $self->{_srcs} = ();
    foreach my $media (@medias) {
        # only index source media
        next unless $media->get_type() eq 'source';

        my $media_id = $media->get_id();
        $self->{_medias}->{$media_id} = 1;
        print STDERR "Indexing media $media_id packages\n" if $self->{_verbose};

        my $index = sub {
            my ($package) = @_;
            $self->{_srcs}->{$media_id}->{$package->get_name()} = {
    		    'revision' => $package->get_version() . '-' . $package->get_release(),
		    'package' => $package
	    };
        };

        $media->traverse_headers($index);
    }
}

sub run {
    my ($self, $media, $resultset) = @_;
    croak "Not a class method" unless ref $self;

    # this is a binary media check only
    return unless $media->get_type() eq 'binary';

    my $allowed_ids = $media->get_option($self->{_id}, 'allowed');

    # abort unless all allowed medias are present
    foreach my $id (@{$allowed_ids}) {
    unless ($self->{_medias}->{$id}) {
            carp "Missing media $id, aborting";
            return;
        }
    }

    my $class = $media->get_package_class();

    my $check_package = sub {
        my ($package) = @_;
        my $id;
        my $canonical_name = $package->get_canonical_name();

        my $bin_revision =
            $package->get_version() . '-' . $package->get_release();

        my $src_revision;
        foreach $id (@{$allowed_ids}) {
            $src_revision = $self->{_srcs}->{$id}->{$canonical_name}->{revision};
            last if $src_revision;
        }

        if ($src_revision) {
	    # we found at least one binary from this source
            undef $self->{_srcs}->{$id}->{$canonical_name}->{package};
            # check if revision match
            unless ($src_revision eq $bin_revision) {
                if ($class->compare_revisions($src_revision, $bin_revision) > 0) {
                    # binary package is obsolete
                    $resultset->add_result($self->{_id}, $media, $package, {
                        package   => $package->get_name(),
                        arch      => $package->get_arch(),
                        revision  => $bin_revision,
                        error     => "Obsolete binaries (source $src_revision found)",
                    });
                } else {
                    # source package is obsolete
                    $resultset->add_result($self->{_id}, $media, $package, {
                        package   => $package->get_canonical_name(),
                        arch      => 'src',
                        revision  => $src_revision,
                        error     => "Obsolete source (binaries $bin_revision found)",
                    });
                }
            }
        } else {
            $resultset->add_result($self->{_id}, $media, $package, {
                package   => $package->get_name(),
                arch      => $package->get_arch(),
                revision  => $bin_revision,
                error     => "Missing source package",
            });
        }
    };

    $media->traverse_headers($check_package);

    foreach my $id (@{$allowed_ids}) {
        foreach my $src (keys %{$self->{_srcs}->{$id}}) {
            my $package = $self->{_srcs}->{$id}->{$src}->{package};
            if ($package) {
                # source package has no binary
                $resultset->add_result($self->{_id}, $media, $package, {
                    package   => $src,
                    arch      => 'src',
                    revision  => $self->{_srcs}->{$id}->{$src}->{revision},
                    error     => "Source without binaries",
                });
            }
        }
    };
}


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
