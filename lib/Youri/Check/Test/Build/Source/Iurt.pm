# $Id$
package Youri::Check::Test::Build::Source::Iurt;

=head1 NAME

Youri::Check::Test::Build::Source::Iurt - Iurt build log source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Build> collects build logs
available from a iurt build bot.

Due to Iurt logs setup (each package have its own directory), there is no real
advantage to preload results. Lazily fetching results uses less bandwidth,
especially when given explicit arch and medias limitations.

=cut

use warnings;
use strict;
use Carp;
use LWP::UserAgent;
use HTML::TokeParser;
use base 'Youri::Check::Test::Build::Source';

my %status = (
    install_deps => 0,
    build        => 1,
    binary_test  => 2
);



=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Build::LBD object.

Specific parameters:

=over

=item url $url

URL of logs for this Iurt instance (default:
http://qa.mandriva.com/build/iurt/cooker)

=item preloading true/false

Allows to load all build logs at initialisation, rather than on-demand
(default: false)

=item medias $medias

List of medias monitored by this Iurt instance. Mandatory if preloading
results, useful to limit bandwidth usage otherwise if defined.

=item arches $arches

List of architectures monitored by this Iurt instance. Mandatory if preloading
results, useful to limit bandwidth usage otherwise if defined.

=item aliases $aliases

Maps given media names to names used by this Iurt instance.

=back

=cut

sub _init {
    my $self    = shift;
    my %options = (
        url     => 'http://qa.mandriva.com/build/iurt/cooker',
        preload => 0,
        medias  => undef,
        arches  => undef,
        aliases => undef,
        @_
    );

    my $agent = LWP::UserAgent->new();

    # try to connect to base URL directly, and abort if not available
    my $response = $agent->head($options{url});
    croak "Unavailable URL $options{url}: " . $response->status_line()
        unless $response->is_success();

    if ($options{preload}) {

        foreach my $arch (@{$options{arches}}) {
            foreach my $media (@{$options{medias}}) {
                my $bot_media = $options{aliases}->{$media} || $media;
                my $base_url = "$options{url}/$arch/$bot_media/log";
                print "Fetching URL $base_url: " if $self->{_verbose} > 1;
                my $response = $agent->get($base_url);
                print $response->status_line() . "\n" if $self->{_verbose} > 1;
                if ($response->is_success()) {
                    my $parser = HTML::TokeParser->new(\$response->content());
                    my $pattern = qr/^(\S+)-([^-]+)-([^-]+)\.src\.rpm\/$/;
                    while (my $token = $parser->get_tag('a')) {
                        my $href = $token->[1]->{href};
                        next unless $href =~ $pattern;
                        my $name = $1;
                        my $version = $2;
                        my $release = $3;
                        my $url = "$base_url/$href";
                        $self->{_results}->{$name}->{$version}->{$release}->{$arch} = $self->_get_package_result($agent, $url);
                    }
                }
            }
        }
    } else {
        $self->{_agent}   = $agent;
        $self->{_url}     = $options{url};
        $self->{_aliases} = $options{aliases};
        if ($options{arches}) {
            $self->{_arches}->{$_} = 1 foreach @{$options{arches}}
        }
        if ($options{medias}) {
            $self->{_medias}->{$_} = 1 foreach @{$options{medias}}
        }
    }
}

sub fails {
    my ($self, $name, $version, $release, $arch, $media) = @_;
    croak "Not a class method" unless ref $self;

    if ($self->{_agent}) {
        # only try monitored arches and medias
        return if $self->{_arches} and ! $self->{_arches}->{$arch};
        return if $self->{_medias} and ! $self->{_medias}->{$media};
       
        my $bot_media = $self->{_aliases}->{$media} || $media;
        my $url = sprintf(
            "%s/%s/%s/log/%s-%s-%s.src.rpm",
            $self->{_url},
            $arch,
            $bot_media,
            $name,
            $version,
            $release
        );
        $self->{_results}->{$name}->{$version}->{$release}->{$arch} =
            $self->_get_package_result($self->{_agent}, $url);
    }

    my $status = 
        $self->{_results}->{$name}->{$version}->{$release}->{$arch}->{status};

    return $status
        && $status ne 'binary_test';
}

sub status {
    my ($self, $name, $version, $release, $arch) = @_;
    croak "Not a class method" unless ref $self;

    return
        $self->{_results}->{$name}->{$version}->{$release}->{$arch}->{status};
}

sub url {
    my ($self, $name, $version, $release, $arch) = @_;
    croak "Not a class method" unless ref $self;

    return
        $self->{_results}->{$name}->{$version}->{$release}->{$arch}->{url};
}

sub _get_package_result {
    my ($self, $agent, $url) = @_;

    my $result;
    print "Fetching URL $url: " if $self->{_verbose} > 1;
    my $response = $agent->get($url);
    print $response->status_line() . "\n" if $self->{_verbose} > 1;
    if ($response->is_success()) {
        my $parser = HTML::TokeParser->new(\$response->content());
        my $pattern = qr/^
            (@{[join('|', keys %status)]}) # any status
            _
            \S+-[^-]+-[^-]+\.src\.rpm      # package name
            \.\d+
            \.log                     
            $/xo;
        while (my $token = $parser->get_tag('a')) {
            my $href = $token->[1]->{href};
            next unless $href =~ $pattern;
            my $status  = $1;
            if (
                !$result->{status} ||
                $status{$result->{status}} < $status{$status}
            ) {
                $result->{status} = $status;
                $result->{url}    = $url . '/' . $href;
            }
        }
    }

    return $result;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
