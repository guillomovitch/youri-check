# $Id$
package Youri::Check::Test::Updates::Source::Debian;

=head1 NAME

Youri::Check::Test::Updates::Source::Debian - Debian updates source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Updates> collects updates
 available from Debian.

=cut

use Carp;
use Moose;
use MooseX::FollowPBP;
use Youri::Types qw/URI/;

extends 'Youri::Check::Test::Updates::Source';

has 'url' => (
    is      => 'ro',
    isa     => URI,
    default => 'http://ftp.debian.org/debian/ls-lR.gz'
);

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates::Source::Debian
object.

Specific parameters:

=over

=item url $url

URL to Debian mirror content file (default: http://ftp.debian.org/debian/ls-lR.gz)

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
