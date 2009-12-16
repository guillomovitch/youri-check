package Youri::Check::Test::Unmaintained;

=head1 NAME

Youri::Check::Test::Unmaintained - Check maintainance

=head1 DESCRIPTION

This plugin checks maintainance status of packages, and reports unmaintained
ones.

=cut

use Carp;
use Moose::Policy 'Moose::Policy::FollowPBP';
use Moose;

extends 'Youri::Check::Test';

our $MONIKER = 'Unmaintained';

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Unmaintained object.

No specific parameters.

=cut

has 'resolver'  => (
    is       => 'rw',
    isa      => 'Youri::Check::Maintainer::Resolver',
    required => 1
);

sub run {
    my ($self, $media) = @_;
    croak "Not a class method" unless ref $self;
    
    # this is a source media check only
    return unless $media->get_type() eq 'source';

    my $database = $self->get_database();
    my $resolver = $self->get_resolver();
    my $verbosity = $self->get_verbosity();

    my $check = sub {
        my ($package) = @_;

        my $error;
        my $maintainer = $resolver->get_maintainer($package);
        if (!$maintainer) {
            $database->add_package_result(
                $MONIKER, $media, $package,
                {
                    error => "unmaintained package"
                }
            );
            $error = 1;
        }

        if ($verbosity > 1) {
            printf
                "checking package $package: %s -> %s\n",
                $maintainer || 'none',
                $error ? 'NOK' : 'OK';
        }
    };

    $media->traverse_headers($check);
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
