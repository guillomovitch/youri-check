# $Id$
package Youri::Check::Plugin::Test::Updates::Source::NetBSD;

=head1 NAME

Youri::Check::Plugin::Test::Updates::Source::NetBSD - NetBSD updates source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Plugin::Test::Updates> collects updates
 available from NetBSD.

=cut

use Moose::Policy 'Moose::Policy::FollowPBP';
use Moose;
use Youri::Types;
use LWP::UserAgent;

extends 'Youri::Check::Plugin::Test::Plugin::Updates::Source';

has 'url' => (
    is => 'rw',
    isa => 'Uri',
    default => 'http://ftp.free.fr/mirrors/ftp.netbsd.org/NetBSD-current/pkgsrc/README-all.html'
);

=head2 new(%args)

Creates and returns a new Youri::Check::Plugin::Test::Updates::Source::NetBSD
object.

Specific parameters:

=over

=item url $url

URL to NetBSD mirror content file: (default: http://ftp.free.fr/mirrors/ftp.netbsd.org/NetBSD-current/pkgsrc/README-all.html)

=back

=cut

sub BUILD {
    my ($self, $params) = @_;

    my $agent = LWP::UserAgent->new();
    my $buffer = '';
    my $pattern = qr/<!-- (.+)-([^-]*?)(?:nb\d*)? \(for sorting\).*?href="([^"]+)"/;
    my $callback = sub {
        my ($data, $response, $protocol) = @_;

        # prepend text remaining from previous run
        $data = $buffer . $data;

        # process current chunk
        while ($data =~ m/(.*)\n/gc) {
            my $line = $1;
            next unless $line =~ $pattern;
            my $name = $1;
            my $version = $2;
            $self->{_versions}->{$1} = $2;
            $self->{_urls}->{$1} = $3;
        }

        # store remaining text
        $buffer = substr($data, pos $data);
    };

    $agent->get($self->get_url(), ':content_cb' => $callback);
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
