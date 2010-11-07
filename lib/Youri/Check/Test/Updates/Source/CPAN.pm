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
use version;
use Carp;
use LWP::UserAgent;
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

    my $agent = LWP::UserAgent->new();
    my $buffer = '';
    my $pattern = qr/>([\w-]+)-v?([\d\.]+)\.tar\.gz<\/a>/;
    my $callback = sub {
        my ($data, $response, $protocol) = @_;

        # prepend text remaining from previous run
        $data = $buffer . $data;

        # process current chunk
        while ($data =~ m/(.*)\n/gc) {
            my $line = $1;
            next unless $line =~ $pattern;
            my $name = $1;
            my $orig_version = $2;
            my $version = version->new($orig_version)->normal();
            $version =~ s/^v//;
            $self->{_versions}->{$name} = $version;
            $self->{_orig_versions}->{$name} = $orig_version;
        }

        # store remaining text
        my $pos = pos $data;
        if ($pos) {
            $buffer = substr($data, pos $data);
        } else {
            $buffer = $data;
        }
    };

    $agent->get($options{url}, ':content_cb' => $callback);
}

sub get_orig_version {
    my ($self, $name) = @_;
    croak "Not a class method" unless ref $self;

    # translate in grabber namespace
    $name = $self->get_name($name);

    # return if aliased to null 
    return unless $name;

    # return original version
    return $self->{_orig_versions}->{$name};
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
