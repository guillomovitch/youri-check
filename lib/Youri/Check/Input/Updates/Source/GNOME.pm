# $Id$
package Youri::Check::Input::Updates::Source::GNOME;

=head1 NAME

Youri::Check::Input::Updates::Source::GNOME - GNOME updates source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Input::Updates> collects updates
available from GNOME.

=cut

use warnings;
use strict;
use Carp;
use LWP::UserAgent;
use HTML::TokeParser;
use List::MoreUtils 'any';
use base 'Youri::Check::Input::Updates::Source';

=head2 new(%args)

Creates and returns a new Youri::Check::Input::Updates::Source::Gnome object.

Specific parameters:

=over

=item url $url

URL to GNOME sources directory (default:
http://fr2.rpmfind.net/linux/gnome.org/sources)

=back

=cut

sub _init {
    my $self    = shift;
    my %options = (
        url => 'http://fr2.rpmfind.net/linux/gnome.org/sources/', # default url
	# We use HTTP as it offers a better sorting (1.2 < 1.10)
        @_
    );

    $self->{_agent} = LWP::UserAgent->new();
    my $response = $self->{_agent}->get($options{url});
    if($response->is_success()) {
        my $parser = HTML::TokeParser->new(\$response->content());
        while (my $token = $parser->get_tag('a')) {
            my $href = $token->[1]->{href};
            next unless $href =~ /^([-\w]+)\/$/o;
            $self->{_names}->{$1} = 1;
        }
    }

    $self->{_url} = $options{url};
}

sub _version {
    my ($self, $name) = @_;
    croak "Not a class method" unless ref $self;

    return unless $self->{_names}->{$name};
    
    my $response = $self->{_agent}->get("$self->{_url}/$name/");
    if($response->is_success()) {
        my $major;
        my $parser = HTML::TokeParser->new(\$response->content());
        while (my $token = $parser->get_tag('a')) {
            my $href = $token->[1]->{href};
            next unless $href =~ /^([.\d]+)\/$/o;
            $major = $1;
        }
        return unless $major;

        $response = $self->{_agent}->get("$self->{_url}/$name/$major/");
        if($response->is_success()) {
            $parser = HTML::TokeParser->new(\$response->content());
            while (my $token = $parser->get_tag('a')) {
                my $href = $token->[1]->{href};
                next unless $href =~ /^LATEST-IS-([.\d]+)$/o;
                return $1;
            }
        }
    }
}

sub _url {
    my ($self, $name) = @_;
    return $self->{_url}."$name/";
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
