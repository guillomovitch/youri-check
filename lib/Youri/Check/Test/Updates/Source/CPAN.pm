# $Id$
package Youri::Check::Test::Updates::Source::CPAN;

=head1 NAME

Youri::Check::Test::Updates::Source::CPAN - CPAN updates source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Updates> collects updates
available from CPAN.

=cut

use Moose::Policy 'Moose::Policy::FollowPBP';
use Moose;
use Youri::Check::Types;
use LWP::UserAgent;

extends 'Youri::Check::Test::Updates::Source';

has 'url' => (
    is => 'rw',
    isa => 'Uri',
    default => 'http://www.cpan.org/modules/01modules.index.html'
);

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates::Source::CPAN object.  

Specific parameters:

=over

=item url $url

URL to CPAN full modules list (default:
http://www.cpan.org/modules/01modules.index.html)

=back

=cut


sub BUILD {
    my ($self, $params) = @_;

    my $agent = LWP::UserAgent->new();
    my $buffer = '';
    my $pattern = qr/>([\w-]+)-([\d\.]+)\.tar\.gz<\/a>/;
    my $callback = sub {
        my ($data, $response, $protocol) = @_;

        # prepend text remaining from previous run
        $data = $buffer . $data;

        # process current chunk
        while ($data =~ m/(.*)\n/gc) {
            my $line = $1;
            next unless $line =~ $pattern;
            $self->{_versions}->{$1} = $2;
        }

        # store remaining text
        $buffer = substr($data, pos $data);
    };

    $agent->get($self->get_url(), ':content_cb' => $callback);
}

sub _get_package_url {
    my ($self, $name) = @_;
    return "http://search.cpan.org/dist/$name";
}

sub _get_converted_package_name {
    my ($self, $name) = @_;
    $name =~ s/^perl-//g;
    return $name;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
