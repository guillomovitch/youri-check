# $Id: Yum.pm 2402 2013-01-08 15:19:27Z guillomovitch $
package Youri::Check::Test::Updates::Source::Fedora;

=head1 NAME

Youri::Check::Test::Updates::Source::Fedora - Fedora updates source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Updates> collects updates
from Fedora distribution.

=cut

use warnings;
use strict;
use Carp;
use LWP::UserAgent;
use base 'Youri::Check::Test::Updates::Source';

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates::Source::Fedora object.

Specific parameters:

=over

=item url $url

URL to SRPMS directory

=back

=cut

sub _init {
    my $self    = shift;
    my %options = (
        url => 'http://archive.fedoraproject.org/pub/fedora/linux/development/rawhide/Everything/source/tree/Packages',
        @_
    );

    my $agent = LWP::UserAgent->new();
    my $buffer = '';
    my $pattern = qr/>([\w-]+)-([\w\.]+)-\d+\.fc\d+\.src\.rpm<\/a>/;
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

    foreach my $char ('0' .. '9', 'a' .. 'z') {
        $agent->get($options{url} . "/$char/", ':content_cb' => $callback);
    }
}

sub _url {
    my ($self, $name) = @_;
    return "http://pkgs.fedoraproject.org/cgit/rpms/$name.git";
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
