# $Id$
package Youri::Check::Maintainer::Resolver::CGI;

=head1 NAME

Youri::Check::Maintainer::Resolver::CGI - CGI-based maintainer resolver

=head1 DESCRIPTION

This is a CGI-based L<Youri::Check::Maintainer::Resolver> implementation.

It uses a remote CGI to resolve maintainers.

=cut

use warnings;
use strict;
use Carp;
use LWP::UserAgent;
use base 'Youri::Check::Maintainer::Resolver';

=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Check::Maintainer::Resolver::CGI object.

Specific parameters:

=over

=item url $url

CGI's URL.

=back

=cut

sub _init {
    my $self    = shift;
    my %options = (
        url        => '', # url to fetch maintainers
        exceptions => undef,
        @_
    );

    croak "No URL given" unless $options{url};

    my $agent = LWP::UserAgent->new();
    my $buffer = '';
    my $pattern = qr/^(\S+)\t(\S+)$/;

    my %exceptions;
    if ($options{exceptions}) {
        croak "exceptions should be a listref"
            unless ref $options{exceptions} eq 'ARRAY';
        %exceptions = map { $_ => 1 } @{$options{exceptions}};
    }

    my $callback = sub {
        my ($data, $response, $protocol) = @_;

        # prepend text remaining from previous run
        $data = $buffer . $data;

        # process current chunk
        while ($data =~ m/(.*)\n/gc) {
            my $line = $1;
            next unless $line =~ $pattern;
            my ($package, $maintainer) = ($1, $2);
            next if %exceptions and $exceptions{$maintainer};
            $self->{_maintainers}->{$package} = $maintainer;
        }

        # store remaining text
        $buffer = substr($data, pos $data);
    };

    $agent->get($options{url}, ':content_cb' => $callback);
}

sub get_maintainer {
    my ($self, $package) = @_;
    croak "Not a class method" unless ref $self;

    print "Retrieving package $package maintainer\n"
        if $self->{_verbose} > 0;

    my $name = ref $package && $package->isa('Youri::Package') ?
        $package->get_canonical_name() :
        $package;

    return $self->{_maintainers}->{$name};
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
