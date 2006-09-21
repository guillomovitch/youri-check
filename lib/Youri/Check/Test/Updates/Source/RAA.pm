# $Id$
package Youri::Check::Test::Updates::Source::RAA;

=head1 NAME

Youri::Check::Test::Updates::Source::RAA - RAA updates source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Updates> collects updates
available from RAA.

=cut

use warnings;
use strict;
use Carp;
use SOAP::Lite;
use List::MoreUtils 'any';
use Youri::Package;
use base 'Youri::Check::Test::Updates::Source';

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates::Source::RAA object.

Specific parameters:

=over

=item url $url

URL to RAA SOAP interface (default:
http://www2.ruby-lang.org/xmlns/soap/interface/RAA/0.0.4)

=back

=cut

sub _init {
    my $self    = shift;
    my %options = (
        url => 'http2://www.ruby-lang.org/xmlns/soap/interface/RAA/0.0.4/',
        @_
    );

    my $raa = SOAP::Lite->service($options{url})
        or croak "Can't connect to $options{url}";
    
    $self->{_raa}   = $raa;
    $self->{_names} = $raa->names();
}

sub get_version {
    my ($self, $package) = @_;
    croak "Not a class method" unless ref $self;

    my $name;
    if (ref $package && $package->isa('Youri::Package')) {
        # don't bother checking for non-ruby packages
        if (
            any { $_->[Youri::Package::DEPENDENCY_NAME] =~ /ruby/ }
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
    $name = $self->get_name($name);

    # return if aliased to null 
    return unless $name;

    # susceptible to throw exception for timeout
    eval {
        my $gem = $self->{_raa}->gem($name);
        return $gem->{project}->{version} if $gem;
    };

    return;
}

sub _url {
    my ($self, $name) = @_;
    return "http://raa.ruby-lang.org/project/$name/";
}

sub _name {
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
