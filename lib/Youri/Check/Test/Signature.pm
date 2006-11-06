# $Id: Rpmlint.pm 567 2005-12-12 21:24:56Z guillomovitch $
package Youri::Check::Test::Signature;

=head1 NAME

Youri::Check::Test::Signature - Check signature

=head1 DESCRIPTION

This plugin checks packages signature, and report unsigned ones. 

=cut

use warnings;
use strict;
use Carp;
use base 'Youri::Check::Test';

my $descriptor = Youri::Check::Descriptor::Row->new(
    cells => [
        Youri::Check::Descriptor::Cell->new(
            name        => 'source package',
            description => 'source package',
            mergeable   => 1,
            value       => 'source_package',
            type        => 'string',
        ),
        Youri::Check::Descriptor::Cell->new(
            name        => 'maintainer',
            description => 'maintainer',
            mergeable   => 1,
            value       => 'maintainer',
            type        => 'email',
        ),
        Youri::Check::Descriptor::Cell->new(
            name        => 'architecture',
            description => 'architecture',
            mergeable   => 0,
            value       => 'arch',
            type        => 'string',
        ),
        Youri::Check::Descriptor::Cell->new(
            name        => 'package',
            description => 'package',
            mergeable   => 0,
            value       => 'package',
            type        => 'string',
        ),
        Youri::Check::Descriptor::Cell->new(
            name        => 'error',
            description => 'error',
            mergeable   => 0,
            value       => 'error',
            type        => 'string',
        )
    ]
);

sub get_descriptor {
    return $descriptor;
}

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Signature object.

Specific parameters:

=over

=item key $key

Expected GPG key identity

=back

=cut

sub _init {
    my $self    = shift;
    my %options = (
        key => '',
        @_
    );

    $self->{_key} = $options{key};
}

sub run {
    my ($self, $media, $resultset) = @_;
    croak "Not a class method" unless ref $self;

    my $check = sub {
        my ($package) = @_;

        my $arch = $package->get_arch();
        my $name = $package->get_name();

        my $key = $package->get_gpg_key();

        if (!$key) {
            $resultset->add_result($self->{_id}, $media, $package, { 
                arch  => $arch,
                file  => $name,
                error => "unsigned package $name"
            });
        } elsif ($key ne $self->{_key}) {
            $resultset->add_result($self->{_id}, $media, $package, { 
                arch    => $arch,
                package => $name,
                error   => "invalid key id $key for package $name (allowed $self->{_key})"
            });
        }
        
    };

    $media->traverse_headers($check);
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
