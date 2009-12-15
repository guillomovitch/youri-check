# $Id$
package Youri::Check::WebRetriever;

=head1 NAME

Youri::Check::WebRetriever - Simple web data retriever

=head1 DESCRIPTION

This class provides a simple web data retriever.

=cut

use Moose::Policy 'Moose::Policy::FollowPBP';
use Moose;
use LWP::UserAgent;
use Youri::Types qw/URI/;
use MooseX::Types::Moose qw/HashRef RegexpRef/;

has 'url'     => ( is => 'ro', isa => URI ); 
has 'pattern' => ( is => 'ro', isa => RegexpRef ); 
has 'results' => ( is => 'rw', isa => HashRef );

sub BUILD {
    my ($self, $params) = @_;

    my $agent  = LWP::UserAgent->new();
    my $results = {};
    my $buffer = '';
    my $callback = sub {
        my ($data, $response, $protocol) = @_;

        # prepend text remaining from previous run
        $data = $buffer . $data;

        # process current chunk
        while ($data =~ m/(.*)\n/gc) {
            my $line = $1;
            next unless $line =~ $params->{pattern};
            $results->{$1} = $2;
        }

        # store remaining text
        my $pos = pos $data;
        if ($pos) {
            $buffer = substr($data, pos $data);
        } else {
            $buffer = $data;
        }
    };

    $agent->get($params->{url}, ':content_cb' => $callback);
    $self->set_results($results);
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
