# $Id: LBD.pm 574 2005-12-27 14:31:16Z guillomovitch $
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
    install_deps => 0,
    build        => 1,
    binary_test  => 2
);

my $pattern = '^('
    . join('|', keys %status)
    . ')_\S+-[^-]+-[^-]+\.src\.rpm\.\d+\.log$';

=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Build::LBD object.

Specific parameters:

=over

=item url $url

URL of logs for this iurt instance (default:
http://qa.mandriva.com/build/iurt/cooker)

=back

=cut

sub _init {
    my $self    = shift;
    my %options = (
        url    => 'http://qa.mandriva.com/build/iurt/cooker',
        @_
    );

    $self->{_agent} = LWP::UserAgent->new();

    # try to connect to base URL directly, and abort if not available
    my $response = $self->{_agent}->head($options{url});
    die "Unavailable URL $options{url}: " . $response->status_line()
        unless $response->is_success();

    $self->{_url} = $options{url};
}

sub fails {
    my ($self, $name, $version, $release, $arch) = @_;

    my $result;
    my $url = "$self->{_url}/$arch/log/$name-$version-$release.src.rpm";
    print "Fetching URL $url: " if $self->{_verbose} > 1;
    my $response = $self->{_agent}->get($url);
    print $response->status_line() . "\n" if $self->{_verbose} > 1;
    if ($response->is_success()) {
        my $parser = HTML::TokeParser->new(\$response->content());
        while (my $token = $parser->get_tag('a')) {
            my $href = $token->[1]->{href};
            next unless $href =~ /$pattern/o;
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

    $self->{_results}->{$name}->{$version}->{$release}->{$arch} = $result;

    return $result->{status} && $result->{status} ne 'binary_test';
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
