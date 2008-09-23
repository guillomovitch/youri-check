# $Id$
package Youri::Check::Plugin::Test::Dependencies;

=head1 NAME

Youri::Check::Plugin::Test::Dependencies - Check dependencies consistency

=head1 DESCRIPTION

This class checks dependencies consistency.

=cut

use Moose::Policy 'Moose::Policy::FollowPBP';
use Moose;
use Carp;
use Youri::Package;

extends 'Youri::Check::Plugin::Test';

use constant MEDIA => 0;
use constant RANGE => 1;

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
            name        => 'architecture',
            description => 'architecture',
            mergeable   => 0,
            value       => 'arch',
            type        => 'string',
        ),
        Youri::Check::Descriptor::Cell->new(
            name        => 'package',
            description => 'package',
            mergeable   => 0,
            value       => 'package',
            type        => 'string',
        ),
        Youri::Check::Descriptor::Cell->new(
            name        => 'error',
            description => 'error',
            mergeable   => 0,
            value       => 'error',
            type        => 'string',
        ),
        Youri::Check::Descriptor::Cell->new(
            name        => 'level',
            description => 'level',
            mergeable   => 0,
            value       => 'level',
            type        => 'string',
        ),
    ]
);

sub get_descriptor {
    return $descriptor;
}

sub prepare {
    my ($self, @medias) = @_;
    croak "Not a class method" unless ref $self;

    foreach my $media (@medias) {
        my $media_id = $media->get_id();
        $self->{_medias}->{$media_id} = 1;
        print STDERR "Indexing media $media_id dependencies\n"
            if $self->{_verbose};

        my $index = sub {
            my ($package) = @_;

            # index provides
            foreach my $provide ($package->get_provides()) {
                push(
                    @{$self->{_provides}->{$provide->get_name()}},
                    [ $media_id, $provide->get_range() ]
                );
            }

            # index files
            foreach my $file ($package->get_files()) {
                push(
                    @{$self->{_files}->{$file->get_name()}},
                    [ $media_id, undef ]
                );
            }
        };
        $media->traverse_headers($index);
    }
}

sub run {
    my ($self, $media, $resultset) = @_;
    croak "Not a class method" unless ref $self;

    my $allowed_ids = $media->get_option($self->{_id}, 'allowed');

    # abort unless all allowed medias are present
    foreach my $id (@{$allowed_ids}) {
        unless ($self->{_medias}->{$id}) {
            carp "Missing media $id, aborting";
            return;
        }
    }

    # index allowed medias
    my %allowed_ids = map { $_ => 1 } @{$allowed_ids};
    my $allowed_ids = join(",", @{$allowed_ids});

    my $class = $media->get_package_class();

    my $check = sub {
        my ($package) = @_;

        my $arch = $package->get_arch();
        my $name = $package->get_name();

        foreach my $require ($package->get_requires()) {

            my $require_name = $require->get_name();
            my $found =
                substr($require_name, 0, 1) eq '/' ?
                    $self->{_files}->{$require_name} :
                    $self->{_provides}->{$require_name};

            my @found = $found ? @$found : ();

            if (!@found) {
                $resultset->add_result($self->{_id}, $media, $package, {
                    arch    => $arch,
                    package => $name,
                    error   => "$require_name not found",
                    level   => Youri::Check::Plugin::Test::ERROR
                });
                next;
            }

            my @found_in_media =
                grep { $allowed_ids{$_->[MEDIA]} }
                @found;

            if (!@found_in_media) {
                $resultset->add_result($self->{_id}, $media, $package, {
                    arch    => $arch,
                    package => $name,
                    error   => "$require_name found in incorrect media $_->[MEDIA] (allowed $allowed_ids)",
                    level   => Youri::Check::Plugin::Test::ERROR
                }) foreach @found;
                next;
            }

            my $require_range = $require->get_range();
            next unless $require_range;

            my @found_in_range =
                grep {
                    !$_->[RANGE] ||
                    $class->check_ranges_compatibility(
                        $require_range,
                        $_->[RANGE]
                    )
                } @found_in_media;

            if (!@found_in_range) {
                $resultset->add_result($self->{_id}, $media, $package, {
                    arch    => $arch,
                    package => $name,
                    error   => "$require_name found with incorrect range $_->[RANGE] (needed $require_range)",
                    level   => Youri::Check::Plugin::Test::ERROR
                }) foreach @found_in_media;
                next;
            }
        }
    };

    $media->traverse_headers($check);
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
