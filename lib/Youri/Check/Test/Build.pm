# $Id$
package Youri::Check::Test::Build;

=head1 NAME

Youri::Check::Test::Build - Check build outputs

=head1 DESCRIPTION

This plugin checks build outputs of packages, and report failures. Additional
source plugins handle specific sources.

=cut

use warnings;
use strict;
use Carp;
use Youri::Utils;
use Youri::Check::Descriptor::Row;
use Youri::Check::Descriptor::Cell;
use base 'Youri::Check::Test';

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
            name        => 'bot',
            description => 'build bot',
            mergeable   => 0,
            value       => 'bot',
            type        => 'string',
        ),
        Youri::Check::Descriptor::Cell->new(
            name        => 'status',
            description => 'build status',
            mergeable   => 0,
            value       => 'status',
            type        => 'string',
            link        => 'url',
        )
    ]
);

sub get_descriptor {
    return $descriptor;
}

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Build object.

Specific parameters:

=over

=item sources $sources

Hash of source plugins definitions

=back

=cut

sub _init {
    my $self    = shift;
    my %options = (
        sources => undef,
        @_
    );

    croak "No source defined" unless $options{sources};
    croak "sources should be an hashref" unless ref $options{sources} eq 'HASH';

    foreach my $id (keys %{$options{sources}}) {
        print "Creating source $id\n" if $options{verbose};
        my $source_conf = $options{sources}->{$id};
        eval {
            push(
            @{$self->{_sources}},
            create_instance(
                    'Youri::Check::Test::Build::Source',
                    $source_conf,
                    {
                        id      => $id,
                        test    => $options{test},
                        verbose => $options{verbose},
                    }
                )
            );
            # register monitored arches
            $self->{_arches}->{$_}->{$id} = 1
                foreach @{$options{sources}->{$id}->{arches}};
        };
        print STDERR "Failed to create source $id: $@\n" if $@;
    }

    croak "no sources created" unless @{$self->{_sources}};
}

sub run {
    my ($self, $media, $resultset) = @_;
    croak "Not a class method" unless ref $self;

    # this is a source media check only
    return unless $media->get_type() eq 'source';

    my $media_id = $media->get_id();

    my $callback = sub {
        my ($package) = @_;

        my $name    = $package->get_name();
        my $version = $package->get_version();
        my $release = $package->get_release();

        foreach my $source (@{$self->{_sources}}) {
            my $source_id = $source->get_id();
            foreach my $arch (keys %{$self->{_arches}}) {
                next unless $self->{_arches}->{$arch}->{$source_id};
                $resultset->add_result($self->{_id}, $media, $package, { 
                    arch   => $arch,
                    bot    => $source_id,
                    status => $source->status($name, $version, $release, $arch),
                    url    => $source->url($name, $version, $release, $arch),
                }) if $source->fails(
                    $name,
                    $version,
                    $release,
                    $arch,
                    $media_id
                );
            }
        }
    };

    $media->traverse_headers($callback);
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
