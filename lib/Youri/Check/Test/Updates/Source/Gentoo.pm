# $Id$
package Youri::Check::Test::Updates::Source::Gentoo;

=head1 NAME

Youri::Check::Test::Updates::Source::Gentoo - Gentoo updates source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Updates> collects updates
available from Gentoo.

=cut

use warnings;
use strict;
use Carp;
use LWP::Simple;
use base 'Youri::Check::Test::Updates::Source';

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates::Source::Gentoo object.

Specific parameters:

=over

=item url $url

URL to Gentoo snapshots directory (default:
http://gentoo.mirror.sdv.fr/snapshots)

=back

=cut


sub _init {
    my $self    = shift;
    my %options = (
        url => 'http://gentoo.mirror.sdv.fr/snapshots', # default URL
        @_
    );

    my $versions;
    my $content = get($options{url});
    my $file;
    while ($content =~ /<A HREF="(portage-\d{8}.tar.bz2)">/g) {
        $file = $1;
    }
    open(INPUT, "GET $options{url}/$file | tar tjf - |") or croak "Can't fetch $options{url}/$file: $!";
    while (my $line = <INPUT>) {
        next unless $line =~ /.*\/([\w-]+)-([\d\.]+)(:?-r\d)?\.ebuild$/;
        $versions->{$1} = $2;
    }
    close(INPUT);

    $self->{_versions} = $versions;
}

sub _url {
    my ($self, $name) = @_;
    return "http://packages.gentoo.org/search/?sstring=$name";
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
