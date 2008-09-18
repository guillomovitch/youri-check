# $Id$
package Youri::Check::Test::Updates::Source::Apache;

=head1 NAME

Youri::Check::Test::Updates::Source::Apache - Apache modules updates source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Updates> collects updates
available for apache modules.

=cut

use warnings;
use strict;
use Carp;
use LWP::UserAgent;
use HTML::TableExtract;
use base 'Youri::Check::Test::Updates::Source';

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates::Source::Apache object.  

Specific parameters:

=over

=item url $url

URL to Apache 2 modules list (default:
http://modules.apache.org/search.php?query=true&apacheversion2=yes)

=back

=cut


sub _init {
    my $self    = shift;
    my %options = (
        url => 'http://modules.apache.org/search.php?query=true&apacheversion2=yes',
        @_
    );

    my $agent = LWP::UserAgent->new();
    my $response = $agent->get($options{url});
    if ($response->is_success()) {
        my $parser = HTML::TableExtract->new(
            attribs   => {width => '100%'},
            keep_html => 1
        );
        $parser->parse($response->content());
        foreach my $table ($parser->tables) {
            my ($name) = $table->cell(0,0) =~ /^<b>([^<]+)<\/b>$/;
            my ($version) = $table->cell(0,1) =~ /<i>([^<]+)<\/i>/;
            my ($id) = $table->cell(4,0) =~ /href="\/search.php\?id=(\d+)"/;
            $self->{_versions}->{$name} = $version;
            $self->{_ids}->{$name} = $id;
        }
    }
}

sub _url {
    my ($self, $name) = @_;
    return "http://modules.apache.org/search.php?id=" . $self->{_ids}->{$name};
}


sub _name {
    my ($self, $name) = @_;
    $name =~ s/^apache-//g;
    return $name;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
