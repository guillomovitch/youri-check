# $Id$
package Youri::Check::Test::Updates::Source::PEAR;

=head1 NAME

Youri::Check::Test::Updates::Source::PEAR - PEAR updates source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Updates> collects updates
available from PEAR.

=cut

use warnings;
use strict;
use Carp;
use LWP::UserAgent;
use XML::Twig;
use base 'Youri::Check::Test::Updates::Source';

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates::Source::PEAR object.  

Specific parameters:

=over

=item mirror $mirror

URL to PEAR mirror (default: http://pear.php.net)

=back

=cut

sub _init {
    my $self    = shift;
    my %options = (
        mirror => 'http://pear.php.net',
        @_
    );

    my $agent = LWP::UserAgent->new();

    my $callback2 = sub {
         my ($twig, $pi) = @_;
         # get name
         my $name = $pi->first_child('p')->first_child('n')->text();
         # get version, if available
         my $a = $pi->first_child('a');
         if ($a) {
             foreach my $r ($a->children('r')) {
                 next unless $r->first_child('s')->text() eq 'stable';
                 my $version = $r->first_child('v')->text();
                 $self->{_versions}->{$name} = $version;
                 last;
             }
         }
         $twig->purge();
    };

    my $callback = sub {
         my ($twig, $c) = @_;
         # get each category information file
         my $info = $c->{att}->{'xlink:href'};
         $info =~ s/info/packagesinfo/;
         my $url = $options{mirror} . $info;
         my $response2 = $agent->get($url);
         my $content2 = $response2->content();
         # correct it, at is is broken
         $content2 =~ s/^<\?xml version="1.0" encoding="UTF-8" \?>//msg;
         # parse it for versions
         my $twig2 = XML::Twig->new(
             TwigRoots => { pi => $callback2 }
         );
         $twig2->parse($content2);
         $twig->purge();
    };

    my $response = $agent->get($options{mirror} . '/rest/c/categories.xml');
    my $twig = XML::Twig->new(
       TwigRoots => { c => $callback }
    );
    $twig->parse($response->content());
}

sub _url {
    my ($self, $name) = @_;
    return "http://pear.php.net/package/$name";
}

sub _name {
    my ($self, $name) = @_;
    $name =~ s/^php-pear-//g;
    return $name;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
