# $Id$
package Youri::Check::Test::Updates::Source::Apache;

=head1 NAME

Youri::Check::Test::Updates::Source::Apache - Apache modules updates source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Updates> collects updates
available for apache modules.

=cut

use warnings;
use strict;
use Carp;
use LWP::UserAgent;
use base 'Youri::Check::Test::Updates::Source';

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates::Source::Apache object.  

Specific parameters:

=over

=item url $url

URL to Apache 2 modules list (default:
http://modules.apache.org/search.php?query=true&apacheversion2=yes)

=back

=cut


sub _init {
    my $self    = shift;
    my %options = (
        url => 'http://modules.apache.org/search.php?query=true&apacheversion2=yes',
        @_
    );

    my $agent = LWP::UserAgent->new();
    my $buffer = '';
    my $pattern = qr/<td bgcolor="#EEEEEE"><b>(\w+)<\/b><\/td><td bgcolor="#EEEEEE" align="right">Version <b><i>([.\w]+)<\/i><\/b><\/td>/;
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
        $buffer = substr($data, pos $data);
    };

    $agent->get($options{url}, ':content_cb' => $callback);
}

sub _name {
    my ($self, $name) = @_;
    $name =~ s/^apache-//g;
    return $name;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
