# $Id$
package Youri::Check::Test::Updates::Source::PEAR;

=head1 NAME

Youri::Check::Test::Updates::Source::PEAR - PEAR updates source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Updates> collects updates
available from PEAR.

=cut

use Moose;
use MooseX::FollowPBP;
use LWP::UserAgent;
use XML::Twig;
use Youri::Types qw/URI/;

extends 'Youri::Check::Test::Updates::Source';

has 'url' => (
    is      => 'ro',
    isa     => URI,
    default => 'http://pear.php.net',
);

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates::Source::PEAR
object.  

Specific parameters:

=over

=item url $url

URL to PEAR mirror (default: http://pear.php.net)

=back

=cut

sub BUILD {
    my ($self, $params) = @_;

    my $agent = LWP::UserAgent->new();
    my $base_url = $self->get_url();

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
         my $url = $base_url . $info;
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

    my $response = $agent->get($base_url . '/rest/c/categories.xml');
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
