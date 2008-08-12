# $Id$
package Youri::Check::Test::Updates::Source::JPackage;

=head1 NAME

Youri::Check::Test::Updates::Source::JPackage - JPackage updates source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Updates> collects updates
available from JPackage.

=cut

use warnings;
use strict;
use Carp;
use LWP::UserAgent;
use base 'Youri::Check::Test::Updates::Source';

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates::Source::JPackage object.

Specific parameters:

=over

=item url $url

URL to Fedora development SRPMS directory (default:
http://mirrors.dotsrc.org/jpackage/1.7/generic)

=back

=cut

sub _init {
    my $self    = shift;
    my %options = (
        url => 'http://mirrors.dotsrc.org/jpackage/1.7/generic',
        @_
    );

    my $agent = LWP::UserAgent->new();
    my $buffer = '';
    my $pattern = qr/>([\w-]+)-([\w\.]+)-[\w\.]+jpp\.src\.rpm<\/a>/;
    my $callback = sub {
        my ($data, $response, $protocol) = @_;

        # prepend text remaining from previous run
        $data = $buffer . $data;

        # process current chunk
        while ($data =~ m/(.*)\n/gc) {
            my $line = $1;
            next unless $line =~ $pattern;
            $self->{_versions}->{$1} = $2;
        }

        # store remaining text
        my $pos = pos $data;
        if ($pos) {
            $buffer = substr($data, pos $data);
        } else {
            $buffer = $data;
        }
    };

    $agent->get("$options{url}/SRPMS.free", ':content_cb' => $callback);
    $agent->get("$options{url}/SRPMS.non-free", ':content_cb' => $callback);
    $agent->get("$options{url}/SRPMS.devel", ':content_cb' => $callback);
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
