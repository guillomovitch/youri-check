# $Id$
package Youri::Check::Test::Updates::Source::NetBSD;

=head1 NAME

Youri::Check::Test::Updates::Source::NetBSD - NetBSD source for updates

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Updates> collects updates
 available from NetBSD.

=cut

use warnings;
use strict;
use Carp;
use LWP::UserAgent;
use base 'Youri::Check::Test::Updates::Source';

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates::Source::NetBSD object.

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

    my $agent = LWP::UserAgent->new();
    my $buffer = '';
    my $callback = sub {
        my ($data, $response, $protocol) = @_;

        # prepend text remaining from previous run
        $data = $buffer . $data;

        # process current chunk
        while ($data =~ m/(.*)\n/ogc) {
            my $line = $1;
            next unless $line =~ /<!-- (.+)-([^-]*?)(?:nb\d*)? \(for sorting\).*?href="([^"]+)"/o;
            my $name = $1;
            my $version = $2;
            $self->{_versions}->{$1} = $2;
            $self->{_urls}->{$1} = $3;
        }

        # store remaining text
        $buffer = substr($data, pos $data);
    };

    $agent->get($options{url}, ':content_cb' => $callback);
}

sub _url {
    my ($self, $name) = @_;
    return $self->{_urls}->{$name};
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
