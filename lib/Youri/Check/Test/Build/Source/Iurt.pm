# $Id$
package Youri::Check::Test::Build::Source::Iurt;

=head1 NAME

Youri::Check::Test::Build::Source::Iurt - Iurt build log source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Build> collects build logs
available from a iurt build bot.

=cut

use warnings;
use strict;
use Carp;
use LWP::UserAgent;
use HTML::TokeParser;
use base 'Youri::Check::Test::Build::Source';

my %status = (
    'recreate_srpm_failure' => 0,
    'install_deps'          => 1,
    'build_failure'         => 2,
);


=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Build::Iurt object.

Specific parameters:

=over

=item url $url

URL of logs for this Iurt instance (default:
http://qa.mandriva.com/build/iurt/cooker)

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

    foreach my $arch (@{$options{arches}}) {
        foreach my $media (@{$options{medias}}) {
            my $bot_media = $options{aliases}->{$media} || $media;
            my $base_url = "$options{url}/$arch/$bot_media/log";
            print "Fetching URL $base_url: " if $self->{_verbose} > 1;
            my $response = $agent->get($base_url."/status.".$bot_media.".log");
            print $response->status_line() . "\n" if $self->{_verbose} > 1;
            if ($response->is_success()) {
                foreach my $line (split /\n/, $response->content()) {
                    next unless $line =~ /^(\S+)-([^-]+)-([^-]+)\.src\.rpm: (.+)$/;
                    my $name = $1;
                    my $version = $2;
                    my $release = $3;
                    my $result = $4;
                    $self->{_results}->{$name}->{$version}->{$release}->{$arch} = {
			    'status' => $result,
			    'url' => "$base_url/$name-$version-$release.src.rpm/"
		    };
                }
            }
        }
    }
}

sub fails {
    my ($self, $name, $version, $release, $arch, $media) = @_;
    croak "Not a class method" unless ref $self;

    return defined($self->{_results}->{$name}->{$version}->{$release}->{$arch})
        && defined($status{$self->{_results}->{$name}->{$version}->{$release}->{$arch}->{status}});
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
