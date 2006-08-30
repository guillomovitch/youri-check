# $Id$
package Youri::Check::Test::Updates::Source::Debian;

=head1 NAME

Youri::Check::Test::Updates::Source::Debian - Debian source for updates

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Updates> collects updates
 available from Debian.

=cut

use warnings;
use strict;
use Carp;
use base 'Youri::Check::Test::Updates::Source';

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates::Source::Debian object.

Specific parameters:

=over

=item url $url

URL to Debian mirror content file (default: http://ftp.debian.org/ls-lR.gz)

=back

=cut

sub _init {
    my $self    = shift;
    my %options = (
        url => 'http://ftp.debian.org/ls-lR.gz',
        @_
    );

    my $versions;
    open(INPUT, "GET $options{url} | zcat |") or croak "Can't fetch $options{url}: $!";
    while (my $line = <INPUT>) {
        next unless $line =~ /([\w\.-]+)_([\d\.]+)\.orig\.tar\.gz$/;
        my $name = $1;
        my $version = $2;
        $versions->{$name} = $version;
    }
    close(INPUT);

    $self->{_versions} = $versions;
}

sub _url {
    my ($self, $name) = @_;
    return "http://packages.debian.org/$name";
}

sub _name {
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
