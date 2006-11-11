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
        url => 'http://gentoo.modulix.net/gentoo/snapshots', # default URL
        @_
    );

    my $versions;
    my $command = "GET $options{url}/portage-latest.tar.bz2 | tar tjf -";
    open(my $input, '-|', $command) or croak "Can't run $command: $!";
    while (my $line = <$input>) {
        next unless $line =~ /.*\/([\w-]+)-([\d\.]+)(:?-r\d)?\.ebuild$/;
        $versions->{$1} = $2;
    }
    close $input;

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
