# $Id$
package Youri::Check::Test::Updates::Source::RAA;

=head1 NAME

Youri::Check::Test::Updates::Source::RAA - RAA updates source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Updates> collects updates
available from RAA.

=cut

use Moose::Policy 'Moose::Policy::FollowPBP';
use Moose;
use LWP::UserAgent;
use HTML::TableExtract;
use Youri::Types qw/URI/;

extends 'Youri::Check::Test::Updates::Source';

has 'url' => (
    is      => 'rw',
    isa     => URI,
    default => 'http://raa.ruby-lang.org/all.html'
);

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates::Source::RAA object.

Specific parameters:

=over

=item url $url

URL to RAA SOAP interface (default: http://raa.ruby-lang.org/all.html)

=back

=cut

sub BUILD {
    my ($self, $params) = @_;

    my $agent = LWP::UserAgent->new();
    my $response = $agent->get($params->{url});
    if ($response->is_success()) {
        my $parser = HTML::TableExtract->new(debug => 1);
        $parser->parse($response->content());
        my $table = $parser->first_table_found();
        foreach my $row ($table->rows()) {
            my $name = $row->[0];
            my $version = $row->[4];
            $name =~ s/\s*$//;
            $version =~ s/\s*$//;
            $self->{_versions}->{$name} = $version;
        }
        delete $self->{_versions}->{Name};
    }

}

sub _get_package_url {
    my ($self, $name) = @_;
    return "http://raa.ruby-lang.org/project/$name/";
}

sub _get_package_name {
    my ($self, $name) = @_;
    return $name;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
