# $Id$
package Youri::Check::Test::Updates::Source::Fedora;

=head1 NAME

Youri::Check::Test::Updates::Source::Fedora - Fedora updates source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Updates> collects updates
available from Fedora.

=cut

use Moose::Policy 'Moose::Policy::FollowPBP';
use Moose;
use Youri::Check::WebRetriever;
use Youri::Types qw/URI/;

extends 'Youri::Check::Test::Updates::Source';

has 'url' => (
    is      => 'rw',
    isa     => URI,
    default => 'http://fr.rpmfind.net/linux/fedora/core/development/source/SRPMS'
);

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates::Source::Fedora 
object.

Specific parameters:

=over

=item url $url

URL to Fedora development SRPMS directory (default:
http://fr.rpmfind.net/linux/fedora/core/development/source/SRPMS)

=back

=cut

sub BUILD {
    my ($self, $params) = @_;

     my $retriever = Youri::Check::WebRetriever->new(
        url     => $params->{url},
        pattern => qr/>([\w-]+)-([\w\.]+)-[\w\.]+\.src\.rpm<\/a>/
    );

    $self->{_versions} = $retriever->get_results();
}

sub _get_package_version {
    my ($self, $name) = @_;
    return $self->{_versions}->{$name};
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
