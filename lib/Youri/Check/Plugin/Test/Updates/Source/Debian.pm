# $Id$
package Youri::Check::Plugin::Test::Updates::Source::Debian;

=head1 NAME

Youri::Check::Plugin::Test::Updates::Source::Debian - Debian updates source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Plugin::Test::Updates> collects updates
 available from Debian.

=cut

use Moose::Policy 'Moose::Policy::FollowPBP';
use Moose;
use Carp;
use Youri::Check::Types;

extends 'Youri::Check::Plugin::Test::Updates::Source';

has 'url' => (
    is => 'rw',
    isa => 'Uri',
    default => 'http://ftp.debian.org/ls-lR.gz'
);

=head2 new(%args)

Creates and returns a new Youri::Check::Plugin::Test::Updates::Source::Debian
object.

Specific parameters:

=over

=item url $url

URL to Debian mirror content file (default: http://ftp.debian.org/ls-lR.gz)

=back

=cut

sub BUILD {
    my ($self, $params) = @_;

    my $versions;
    my $pattern = qr/([\w\.-]+)_([\d\.]+)\.orig\.tar\.gz$/;
    my $command = 'GET ' . $self->get_url() . '| zcat';
    open(my $input, '-|', $command) or croak "Can't run $command: $!\n";
    while (my $line = <$input>) {
        next unless $line =~ $pattern;
        my $name = $1;
        my $version = $2;
        $versions->{$name} = $version;
    }
    close $input;

    $self->{_versions} = $versions;
}

sub _get_package_version {
    my ($self, $name) = @_;
    return $self->{_versions}->{$name};
}

sub _get_package_url {
    my ($self, $name) = @_;
    return "http://packages.debian.org/$name";
}

sub _get_package_name {
    my ($self, $name) = @_;
    
    if ($name =~ /^(perl|ruby)-([-\w]+)$/) {
        $name = lc("lib$2-$1");
    } elsif ($name =~ /^apache-([-\w]+)$/) {
        $name = "libapache-$1";
        $name =~ s/_/-/g;
    }

    return $name;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
