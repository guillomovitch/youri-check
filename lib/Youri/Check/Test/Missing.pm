package Youri::Check::Test::Missing;

=head1 NAME

Youri::Check::Test::Missing - Check components consistency

=head1 DESCRIPTION

This plugin checks consistency between package components, and report outdated
ones.

=cut

use Moose::Policy 'Moose::Policy::FollowPBP';
use Moose;
use Carp;
use List::MoreUtils qw/all any/;

extends 'Youri::Check::Test';

our $MONIKER = 'Missing';

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
	    };
        };

        $media->traverse_headers($index);
    }
}

sub run {
    my ($self, $media)  = @_;
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
    my $database = $self->get_database();

    my $check_package = sub {
        my ($package) = @_;
        my $id;
        my $canonical_name = $package->get_canonical_name();

        my $bin_revision = $package->get_canonical_revision();

        my $src_revision;
        foreach my $id (@{$allowed_ids}) {
            $src_revision = $self->{_srcs}->{$id}->{$canonical_name}->{revision};
            last if $src_revision;
        }

        if ($src_revision) {
            # check if revision match
            unless ($src_revision eq $bin_revision) {
                if ($class->compare_revisions($src_revision, $bin_revision) > 0) {
                    # binary package is obsolete
                    $database->add_package_result(
                        $MONIKER, $media, $package,
                        {
                            rpm   => $package->get_name(),
                            arch  => $package->get_arch(),
                            build => $bin_revision,
                            error => "Obsolete binaries (source $src_revision found)",
                        }
                    );
                } else {
                    # source package is obsolete
                    $database->add_package_result(
                        $MONIKER, $media, $package,
                        {
                            rpm   => $package->get_canonical_name(),
                            arch  => 'src',
                            build => $src_revision,
                            error => "Obsolete source (binaries $bin_revision found)",
                        }
                    );
                }
            }
        } else {
            $database->add_package_result(
                $MONIKER, $media, $package,
                {
                    rpm   => $package->get_name(),
                    arch  => $package->get_arch(),
                    build => $bin_revision,
                    error => "Missing source package",
                }
            );
        }
    };

    $media->traverse_headers($check_package);
}


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
