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
use Youri::Check::Types;
use Carp;
use SOAP::Lite;
use List::MoreUtils 'any';

extends 'Youri::Check::Test::Updates::Source';

has 'url' => (
    is => 'rw',
    isa => 'Uri',
    default => 'http://www2.ruby-lang.org/xmlns/soap/interface/RAA/0.0.4'
);
has 'raa' => (
    is => 'ro',
    isa => 'SOAP::Lite'
    default => sub { SOAP::Lite->new() } 
);

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates::Source::RAA object.

Specific parameters:

=over

=item url $url

URL to RAA SOAP interface (default:
http://www2.ruby-lang.org/xmlns/soap/interface/RAA/0.0.4)

=back

=cut

sub BUILD {
    my ($self, $params) = @_;

    $self->get_raa()->service($self->get_url())
        or croak "Can't connect to " . $self->get_url();
    
    $self->{_names} = $raa->names();
}

sub get_package_version {
    my ($self, $package) = @_;
    croak "Not a class method" unless ref $self;

    my $name;
    if (ref $package && $package->isa('Youri::Package')) {
        # don't bother checking for non-ruby packages
        if (
            any { $_->get_name() =~ /ruby/ }
            $package->get_requires()
        ) {
            $name = $package->get_canonical_name();
        } else {
            return;
        }
    } else {
        $name = $package;
    }

    # translate in grabber namespace
    $name = $self->get_converted_package_name($name);

    # return if aliased to null 
    return unless $name;

    # susceptible to throw exception for timeout
    eval {
        my $gem = $self->{_raa}->gem($name);
        return $gem->{project}->{version} if $gem;
    };

    return;
}

sub _get_package_url {
    my ($self, $name) = @_;
    return "http://raa.ruby-lang.org/project/$name/";
}

sub _get_package_name {
    my ($self, $name) = @_;

    if (ref $self) {
        my $match = $name;
        $match =~ s/^ruby[-_]//;
        $match =~ s/[-_]ruby$//;
        my @results =
            grep { /^(ruby[-_])?\Q$match\E([-_]ruby)$/ }
            @{$self->{_names}};
        if (@results) {
            return $results[0];
        } else {
            return $name;
        }
    } else {
        return $name;
    }
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
