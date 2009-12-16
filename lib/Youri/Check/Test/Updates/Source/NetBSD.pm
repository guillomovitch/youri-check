# $Id$
package Youri::Check::Test::Updates::Source::NetBSD;

=head1 NAME

Youri::Check::Test::Updates::Source::NetBSD - NetBSD updates source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Updates> collects updates
 available from NetBSD.

=cut

use Moose::Policy 'Moose::Policy::FollowPBP';
use Moose;
use Youri::Check::WebRetriever;
use Youri::Types qw/URI/;

extends 'Youri::Check::Test::Updates::Source';

has 'url' => (
    is      => 'ro',
    isa     => URI,
    default => 'http://ftp.free.fr/mirrors/ftp.netbsd.org/NetBSD-current/pkgsrc/README-all.html'
);

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates::Source::NetBSD
object.

Specific parameters:

=over

=item url $url

URL to NetBSD mirror content file: (default: http://ftp.free.fr/mirrors/ftp.netbsd.org/NetBSD-current/pkgsrc/README-all.html)

=back

=cut

sub BUILD {
    my ($self, $params) = @_;

    my $retriever = Youri::Check::WebRetriever->new(
        url     => $params->{url},
        pattern => qr/<!-- (.+)-([^-]*?)(?:nb\d*)? \(for sorting\).*?href="([^"]+)"/
    );

    $self->{_versions} = $retriever->get_results();
}

sub _get_package_version {
    my ($self, $name) = @_;
    return $self->{_versions}->{$name};
}

sub _get_package_url {
    my ($self, $name) = @_;
    return $self->{_urls}->{$name};
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
