# $Id$
package Youri::Check::Test::Updates::Source::CPAN;

=head1 NAME

Youri::Check::Test::Updates::Source::CPAN - CPAN updates source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Updates> collects updates
available from CPAN.

=cut

use warnings;
use strict;
use Carp;
use base 'Youri::Check::Test::Updates::Source';

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates::Source::CPAN object.  

Specific parameters:

=over

=item url $url

URL to CPAN full modules list (default:
http://www.cpan.org/modules/01modules.index.html)

=back

=cut


sub _init {
    my $self    = shift;
    my %options = (
        url => 'http://www.cpan.org/modules/01modules.index.html',
        @_
    );

    my $versions;
    my $command = "GET $options{url}";
    open(my $input, '-|', $command) or croak "Can't run $command: $!";
    while (my $line = <$input>) {
        next unless $line =~ />([\w-]+)-([\d\.]+)\.tar\.gz<\/a>/o;
        $versions->{$1} = $2;
    }
    close $input;

    $self->{_versions} = $versions;
}

sub _url {
    my ($self, $name) = @_;
    return "http://search.cpan.org/dist/$name";
}

sub _name {
    my ($self, $name) = @_;
    $name =~ s/^perl-//g;
    return $name;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
