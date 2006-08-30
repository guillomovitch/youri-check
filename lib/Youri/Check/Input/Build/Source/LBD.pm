# $Id$
package Youri::Check::Input::Build::Source::LBD;

=head1 NAME

Youri::Check::Input::Build::Source::LBD - LBD build log source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Input::Build> collects build logs
available from a LBD build bot.

=cut

use warnings;
use strict;
use Carp;
use LWP::UserAgent;
use HTML::TokeParser;
use base 'Youri::Check::Input::Build::Source';

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

Creates and returns a new Youri::Check::Input::Build::LBD object.

Specific parameters:

=over

=item url $url

URL of logs for this LBD instance (default: http://eijk.homelinux.org/build)

=item medias $medias

List of medias monitored by this LBD instance

=item archs $archs

List of architectures monitored by this LBD instance

=back

=cut

sub _init {
    my $self    = shift;
    my %options = (
        url    => 'http://eijk.homelinux.org/build',
        medias => undef,
        archs  => undef,
        @_
    );

    my $agent   = LWP::UserAgent->new();

    # try to connect to base URL directly, and abort if not available
    my $response = $agent->head($options{url});
    die "Unavailable URL $options{url}: " . $response->status_line()
        unless $response->is_success();

    my $pattern = '^(\S+)-([^-]+)-([^-]+)(?:\.gz)?$';

    foreach my $arch (@{$options{archs}}) {
        foreach my $media (@{$options{medias}}) {
            my $url_base = "$options{url}/$arch/$media/BO";
            foreach my $status (@status) {
                my $url = "$url_base/$status/";
                print "Fetching URL $url: " if $self->{_verbose} > 1;
                my $response = $agent->get($url);
                print $response->status_line() . "\n" if $self->{_verbose} > 1;
                if ($response->is_success()) {
                    my $parser = HTML::TokeParser->new(\$response->content());
                    while (my $token = $parser->get_tag('a')) {
                        my $href = $token->[1]->{href};
                        next unless $href =~ /$pattern/o;
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
}

sub fails {
    my ($self, $name, $version, $release, $arch) = @_;

    my $status =
        $self->{_results}->{$name}->{$version}->{$release}->{$arch}->{status};

    return $status && $status ne 'OK' && $status ne 'arch_excl';
}

sub status {
    my ($self, $name, $version, $release, $arch) = @_;
    return
        $self->{_results}->{$name}->{$version}->{$release}->{$arch}->{status};
}

sub url {
    my ($self, $name, $version, $release, $arch) = @_;
    return
        $self->{_results}->{$name}->{$version}->{$release}->{$arch}->{url};
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
