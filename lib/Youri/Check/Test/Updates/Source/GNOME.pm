# $Id$
package Youri::Check::Test::Updates::Source::GNOME;

=head1 NAME

Youri::Check::Test::Updates::Source::GNOME - GNOME updates source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Updates> collects updates
available from GNOME.

=cut

use Carp;
use Moose;
use MooseX::FollowPBP;
use HTML::TokeParser;
use List::MoreUtils 'any';
use Youri::Check::Types qw/Agent/;
use Youri::Types qw/URI/;

extends 'Youri::Check::Test::Updates::Source';

has 'url' => (
    is      => 'ro',
    isa     => URI,
    default => 'http://fr2.rpmfind.net/linux/gnome.org/sources'
);
has 'agent' => (
    is      => 'ro',
    isa     => Agent,
    default => sub { LWP::UserAgent->new() } 
);

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates::Source::Gnome
object.

Specific parameters:

=over

=item url $url

URL to GNOME sources directory (default:
http://fr2.rpmfind.net/linux/gnome.org/sources)

=back

=cut

sub BUILD {
    my ($self, $params) = @_;

    my $response = $self->get_agent()->get($self->get_url());
    if($response->is_success()) {
        my $parser = HTML::TokeParser->new(\$response->content());
        my $pattern = qr/^([-\w]+)\/$/;
        while (my $token = $parser->get_tag('a')) {
            my $href = $token->[1]->{href};
            next unless $href =~ $pattern;
            $self->{_names}->{$1} = 1;
        }
    }
}

sub _get_package_version {
    my ($self, $name) = @_;

    return unless $self->{_names}->{$name};
    
    my $response = $self->get_agent()->get(
        $self->get_url() . "/$name/"
    );
    return unless $response->is_success();

    my $major;
    my $parser = HTML::TokeParser->new(\$response->content());
    my $pattern = qr/^([.\d]+)\/$/;
    while (my $token = $parser->get_tag('a')) {
        my $href = $token->[1]->{href};
        next unless $href =~ $pattern;
        $major = $1;
    }
    return unless $major;

    $response = $self->get_agent()->get(
        $self->get_url() . "/$name/$major/"
    );
    return unless $response->is_success();

    $parser = HTML::TokeParser->new(\$response->content());
    $pattern = qr/^LATEST-IS-([.\d]+)$/;
    while (my $token = $parser->get_tag('a')) {
        my $href = $token->[1]->{href};
        next unless $href =~ $pattern;
        return $1;
    }
}

sub _get_package_url {
    my ($self, $name) = @_;
    return $self->get_url() . "/$name/";
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
