# $Id$
package Youri::Check::Test::Updates::Source::JPackage;

=head1 NAME

Youri::Check::Test::Updates::Source::JPackage - JPackage updates source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Updates> collects updates
available from JPackage.

=cut

use Moose;
use MooseX::FollowPBP;
use Youri::Check::WebRetriever;
use Youri::Types qw/URI/;

extends 'Youri::Check::Test::Updates::Source';

has 'url' => (
    is      => 'ro',
    isa     => URI,
    default => 'http://mirrors.dotsrc.org/jpackage/1.7/generic'
);

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates::Source::JPackage object.

Specific parameters:

=over

=item url $url

URL to Fedora development SRPMS directory (default:
http://mirrors.dotsrc.org/jpackage/1.7/generic)

=back

=cut

sub BUILD {
    my ($self, $params) = @_;

    my $base_url = $self->get_url();
    my $free_retriever = Youri::Check::WebRetriever->new(
        url     => "$base_url/SRPMS.free",
        pattern => qr/>([\w-]+)-([\w\.]+)-[\w\.]+jpp\.src\.rpm<\/a>/
    );

    my $non_free_retriever = Youri::Check::WebRetriever->new(
        url     => "$base_url/SRPMS.non-free",
        pattern => qr/>([\w-]+)-([\w\.]+)-[\w\.]+jpp\.src\.rpm<\/a>/
    );

    my $devel_retriever = Youri::Check::WebRetriever->new(
        url     => "$base_url/SRPMS.devel",
        pattern => qr/>([\w-]+)-([\w\.]+)-[\w\.]+jpp\.src\.rpm<\/a>/
    );

    $self->{_versions} = {
        %{$free_retriever->get_results()},
        %{$non_free_retriever->get_results()},
        %{$devel_retriever->get_results()},
    };
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
