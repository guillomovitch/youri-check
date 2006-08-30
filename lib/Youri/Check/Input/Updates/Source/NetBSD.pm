# $Id$
package Youri::Check::Input::Updates::Source::NetBSD;

=head1 NAME

Youri::Check::Input::Updates::Source::NetBSD - NetBSD source for updates

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Input::Updates> collects updates
 available from NetBSD.

=cut

use warnings;
use strict;
use Carp;
use base 'Youri::Check::Input::Updates::Source';
use IO::Ftp;

=head2 new(%args)

Creates and returns a new Youri::Check::Input::Updates::Source::NetBSD object.

Specific parameters:

=over

=item url $url

URL to NetBSD mirror content file, without ftp: (default: //ftp.free.fr/mirrors/ftp.netbsd.org/NetBSD-current/pkgsrc/README-all.html)

=back

=cut

sub _init {
    my $self    = shift;
    my %options = (
        url => '//ftp.free.fr/mirrors/ftp.netbsd.org/NetBSD-current/pkgsrc/README-all.html',
        @_
    );

    my $versions;
    my $urls;

    my $in = IO::Ftp->new('<',$options{url}) or croak "Can't fetch $options{url}: $!";
    while (my $line = <$in>) {
        next unless $line =~ /<!-- (.+)-([^-]*?)(nb\d*)? \(for sorting\).*?href="([^"]+)"/;
        my $name = $1;
        my $version = $2;
        $versions->{$name} = $version;
        $urls->{$name} = $4;
    }
    close($in);

    $self->{_versions} = $versions;
    $self->{_urls} = $urls;
    $self->{_url} = $options{url};
}

sub _url {
    my ($self, $name) = @_;
    return 'ftp://ftp.free.fr/mirrors/ftp.netbsd.org/NetBSD-current/pkgsrc/' . $self->{_urls}->{$name};
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
