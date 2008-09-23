package Youri::Check::Plugin::Test::Orphans;

=head1 NAME

Youri::Check::Plugin::Test::Orphans - Check maintainance

=head1 DESCRIPTION

This plugin checks maintainance status of packages, and reports unmaintained
ones.

=cut

use warnings;
use strict;
use Carp;
use base 'Youri::Check::Plugin::Test';
use version; our $VERSION = qv('0.1.0');

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

Creates and returns a new Youri::Check::Plugin::Test::Orphans object.

No specific parameters.

=cut

sub _init {
    my $self    = shift;
    my %options = (
        resolver => undef,
        @_
    );

    croak "No resolver defined" unless $options{resolver};

    $self->{_resolver} = $options{resolver};
}

sub run {
    my ($self, $media, $resultset) = @_;
    croak "Not a class method" unless ref $self;
    
    # this is a source media check only
    return unless $media->get_type() eq 'source';

    my $check = sub {
        my ($package) = @_;
        $resultset->add_result($self->{_id}, $media, $package, {
            error => "unmaintained package"
        }) unless $self->{_resolver}->get_maintainer($package);
    };

    $media->traverse_headers($check);
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
