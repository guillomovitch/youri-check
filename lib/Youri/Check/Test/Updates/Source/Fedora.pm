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
use LWP::UserAgent;
use XML::Twig;
use base 'Youri::Check::Test::Updates::Source::Yum';

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates::Source::Fedora object.

Specific parameters:

=over

=item url $url

URL to Fedora development SRPMS directory (default:
http://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/source/SRPMS)

=back

=cut

sub _init {
    my $self    = shift;
    my %options = (
        url => 'http://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/source/SRPMS',
        @_
    );

    $self->SUPER::_init(%options);
}

sub _url {
    my ($self, $name) = @_;
    return "http://pkgs.fedoraproject.org/gitweb/?p=$name.git";
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
