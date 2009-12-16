# $Id$
package Youri::Check::Test::Build;

=head1 NAME

Youri::Check::Test::Build - Check build outputs

=head1 DESCRIPTION

This plugin checks build outputs of packages, and report failures. Additional
source plugins handle specific sources.

=cut

use Carp;
use Moose::Policy 'Moose::Policy::FollowPBP';
use Moose;
use Youri::Check::Types qw/HashRefOfBuildSources/;

extends 'Youri::Check::Test';

our $MONIKER = 'Build';

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Build object.

Specific parameters:

=over

=item sources $sources

Hash of source plugins definitions

=back

=cut

has 'sources' => (
    is       => 'rw',
    isa      => HashRefOfBuildSources,
    coerce   => 1,
    required => 1
);

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
