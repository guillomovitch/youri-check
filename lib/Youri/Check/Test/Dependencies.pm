# $Id$
package Youri::Check::Test::Dependencies;

=head1 NAME

Youri::Check::Test::Dependencies - Check dependencies consistency

=head1 DESCRIPTION

This class checks dependencies consistency.

=cut

use warnings;
use strict;
use Carp;
use Youri::Package;
use Youri::Check::Descriptor::Row;
use Youri::Check::Descriptor::Cell;
use base 'Youri::Check::Test';

use constant MEDIA => 0;
use constant RANGE => 1;

my $descriptor = Youri::Check::Descriptor::Row->new(
    cells => [
        Youri::Check::Descriptor::Cell->new(
            name        => 'package',
            description => 'package',
            mergeable   => 1,
            value       => 'package',
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
            name        => 'file',
            description => 'file',
            mergeable   => 0,
            value       => 'file',
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
                    @{$self->{_provides}->{$provide->[Youri::Package::DEPENDENCY_NAME]}},
                    [ $media_id, $provide->[Youri::Package::DEPENDENCY_RANGE] ]
                );
            }

            # index files
            foreach my $file ($package->get_files()) {
                push(
                    @{$self->{_files}->{$file->[Youri::Package::FILE_NAME]}},
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

    my @allowed_ids = $media->allow_deps();

    # abort unless all allowed medias are present
    foreach my $id (@allowed_ids) {
        unless ($self->{_medias}->{$id}) {
            carp "Missing media $id, aborting";
            return;
        }
    }

    # index allowed medias
    my %allowed_ids = map { $_ => 1 } @allowed_ids;
    my $allowed_ids = join(",", @allowed_ids);

    my $class = $media->get_package_class();

    my $check = sub {
        my ($package) = @_;

        my $arch = $package->get_arch();
        my $name = $package->get_name();

        foreach my $require ($package->get_requires()) {

            my $found =
                substr($require->[Youri::Package::DEPENDENCY_NAME], 0, 1) eq '/' ?
                    $self->{_files}->{$require->[Youri::Package::DEPENDENCY_NAME]} :
                    $self->{_provides}->{$require->[Youri::Package::DEPENDENCY_NAME]};

            my @found = $found ? @$found : ();

            if (!@found) {
                $resultset->add_result($self->{_id}, $media, $package, {
                    arch  => $arch,
                    file  => $name,
                    error => "$require->[Youri::Package::DEPENDENCY_NAME] not found",
                    level => Youri::Check::Test::ERROR
                });
                next;
            }

            my @found_in_media =
                grep { $allowed_ids{$_->[MEDIA]} }
                @found;

            if (!@found_in_media) {
                $resultset->add_result($self->{_id}, $media, $package, {
                    arch  => $arch,
                    file  => $name,
                    error => "$require->[Youri::Package::DEPENDENCY_NAME] found in incorrect media $_->[MEDIA] (allowed $allowed_ids)",
                    level => Youri::Check::Test::ERROR
                }) foreach @found;
                next;
            }

            next unless $require->[Youri::Package::DEPENDENCY_RANGE];

            my @found_in_range =
                grep {
                    !$_->[RANGE] ||
                    $class->are_ranges_compatible(
                        $require->[Youri::Package::DEPENDENCY_RANGE],
                        $_->[RANGE]
                    )
                } @found_in_media;

            if (!@found_in_range) {
                $resultset->add_result($self->{_id}, $media, $package, {
                    arch  => $arch,
                    file  => $name,
                    error => "$require->[Youri::Package::DEPENDENCY_NAME] found with incorrect range $_->[RANGE] (needed $require->[Youri::Package::DEPENDENCY_RANGE])",
                    level => Youri::Check::Test::ERROR
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
