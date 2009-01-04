# $Id$
package Youri::Check::Test::Updates::Source::PyPI;

=head1 NAME

Youri::Check::Test::Updates::Source::PyPI - Python Package Index updates source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Updates> collects updates
available from Python Package Index.

=cut

use warnings;
use strict;
use Carp;
use LWP::UserAgent;
use base 'Youri::Check::Test::Updates::Source';

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates::Source::PyPI object.  

Specific parameters:

=over

=item url $url

URL to PyPI packages index (default:
http://pypi.python.org/pypi?%3Aaction=index)

=back

=cut


sub _init {
    my $self    = shift;
    my %options = (
        url => 'http://pypi.python.org/pypi?%3Aaction=index',
        @_
    );

    my $agent = LWP::UserAgent->new();
    my $buffer = '';
    my $pattern = qr/<td><a href="[^"]+">([\w-]+)&nbsp;([\d\.]+)<\/a><\/td>/;
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

    $agent->get($options{url}, ':content_cb' => $callback);
}

sub _url {
    my ($self, $name) = @_;
    return "http://pypi.python.org/pypi/$name";
}

sub _name {
    my ($self, $name) = @_;
    $name =~ s/^python-//g;
    return $name;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
