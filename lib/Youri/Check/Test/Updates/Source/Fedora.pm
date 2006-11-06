# $Id$
package Youri::Check::Test::Updates::Source::Fedora;

=head1 NAME

Youri::Check::Test::Updates::Source::Fedora - Fedora updates source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Updates> collects updates
available from Fedora.

=cut

use warnings;
use strict;
use Carp;
use base 'Youri::Check::Test::Updates::Source';

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates::Source::Fedora object.

Specific parameters:

=over

=item url $url

URL to Fedora development SRPMS directory (default:
http://fr.rpmfind.net/linux/fedora/core/development/SRPMS)

=back

=cut

sub _init {
    my $self    = shift;
    my %options = (
        url => 'http://fr.rpmfind.net/linux/fedora/core/development/SRPMS',
        @_
    );

    my $versions;
    my $command = "GET $options{url}";
    open(my $input, '-|', $command) or croak "Can't run $command: $!";
    while (my $line = <$input>) {
        next unless $line =~ />([\w-]+)-([\w\.]+)-[\w\.]+\.src\.rpm<\/a>/;
        $versions->{$1} = $2;
    }
    close $input;

    $self->{_versions} = $versions;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
