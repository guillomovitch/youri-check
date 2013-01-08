# $Id$
package Youri::Check::Test::Updates::Source::Yum;

=head1 NAME

Youri::Check::Test::Updates::Source::Yum - Yum updates source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Updates> collects updates
from any yum-based distribution.

=cut

use warnings;
use strict;
use Carp;
use LWP::UserAgent;
use XML::Twig;
use base 'Youri::Check::Test::Updates::Source';

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates::Source::Yum object.

Specific parameters:

=over

=item url $url

URL to SRPMS directory

=back

=cut

sub _init {
    my $self    = shift;
    my %options = (
        @_
    );

    my $agent = LWP::UserAgent->new();
    my $buffer = '';
    my $repodata_xml;
    my $pattern = qr/>([0-9a-f]*-primary.xml.gz)</;
    my $callback = sub {
        my ($data, $response, $protocol) = @_;

        # prepend text remaining from previous run
        $data = $buffer . $data;

        # process current chunk
        while ($data =~ m/(.*)\n/gc) {
            my $line = $1;
            next unless $line =~ $pattern;
            $repodata_xml = $1;
        }

        # store remaining text
        my $pos = pos $data;
        if ($pos) {
            $buffer = substr($data, pos $data);
        } else {
            $buffer = $data;
        }
    };

    $agent->get($options{url} . '/repodata/', ':content_cb' => $callback);

    my $versions;
   
    my $package_cb = sub {
        my ($twig, $package) = @_;
        my $name =  $package->first_child('name')->text();
        my $version = $package->first_child('version')->{'att'}->{'ver'};
        $versions->{$name} = $version;
        $twig->purge();
    };
    my $twig = XML::Twig->new(
       TwigRoots => { package => $package_cb }
    );

    my $url = $options{url} . '/repodata/' . $repodata_xml;
    my $command = "GET $url | zcat";
    open(my $input, '-|', $command) or croak "Can't run $command: $!\n";
    $twig->parse($input);
    close $input;

    $self->{_versions} = $versions;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
