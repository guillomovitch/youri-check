# $Id$
package Youri::Check::Test::Build::Source::LBD;

=head1 NAME

Youri::Check::Test::Build::Source::LBD - LBD build log source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Build> collects build logs
available from a LBD build bot.

Due to LBD logs setup (one directory for each build status), preloading results
is highly advantageous.

=cut

use warnings;
use strict;
use Carp;
use LWP::UserAgent;
use HTML::TokeParser;
use base 'Youri::Check::Test::Build::Source';

my @status = qw/
    OK
    arch_excl
    broken
    cannot_be_installed
    debug
    dependency
    file_not_found
    multiarch
    problem
    unpackaged_files
/;


=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Build::LBD object.

Specific parameters:

=over

=item url $url

URL of logs for this LBD instance (default: http://eijk.homelinux.org/build)

=item preloading true/false

Allows to load all build logs at initialisation, rather than on-demand
(default: false)

=item medias $medias

List of medias monitored by this LBD instance. Mandatory if preloading
results, useful to limit bandwidth usage otherwise if defined.

=item archs $archs

List of architectures monitored by this LBD instance. Mandatory if preloading
results, useful to limit bandwidth usage otherwise if defined.

=item aliases $aliases

Maps given media names to names used by this LBD instance.

=back

=cut

sub _init {
    my $self    = shift;
    my %options = (
        url     => 'http://eijk.homelinux.org/build',
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
                my $base_url = "$options{url}/$arch/$bot_media/BO";
                foreach my $status (@status) {
                    my $url = "$base_url/$status";
                    print "Fetching URL $url: " if $self->{_verbose} > 1;
                    my $response = $agent->get($url);
                    print $response->status_line() . "\n" if $self->{_verbose} > 1;
                    if ($response->is_success()) {
                        my $parser = HTML::TokeParser->new(\$response->content());
                        my $pattern = qr/^(\S+)-([^-]+)-([^-]+)(?:\.gz)?$/;
                        while (my $token = $parser->get_tag('a')) {
                            my $href = $token->[1]->{href};
                            next unless $href =~ $pattern;
                            my $name    = $1;
                            my $version = $2;
                            my $release = $3;
                            my $result;
                            $result->{status} = $status;
                            $result->{url}    = $url . '/' . $href;
                            $self->{_results}->{$name}->{$version}->{$release}->{$arch} = $result;
                        }
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
        my $base_url = "$self->{_url}/$arch/$bot_media/BO";
        STATUS: foreach my $status (@status) {
            my $url = "$base_url/$status/";
            print "Fetching URL $url: " if $self->{_verbose} > 1;
            my $response = $self->{_agent}->get($url);
            print $response->status_line() . "\n" if $self->{_verbose} > 1;
            if ($response->is_success()) {
                my $parser = HTML::TokeParser->new(\$response->content());
                my $pattern = qr/^$name-$version-$release(?:\.gz)?$/;
                while (my $token = $parser->get_tag('a')) {
                    my $href = $token->[1]->{href};
                    next unless $href =~ $pattern;
                    my $result;
                    $result->{status} = $status;
                    $result->{url}    = $url . '/' . $href;
                    $self->{_results}->{$name}->{$version}->{$release}->{$arch} = $result;
                    last STATUS;
                }
            }
        }
    }

    my $status =
        $self->{_results}->{$name}->{$version}->{$release}->{$arch}->{status};

    return $status
        && $status ne 'OK'
        && $status ne 'arch_excl';
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

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
