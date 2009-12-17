# $Id$
package Youri::Check::Test::Age;

=head1 NAME

Youri::Check::Test::Age - Check maximum age

=head1 DESCRIPTION

This plugin checks packages age, and report the ones exceeding maximum limit.

=cut

use Carp;
use DateTime::Format::Duration;
use Moose::Policy 'Moose::Policy::FollowPBP';
use Moose;
use MooseX::Types::Moose qw/Str/;
use Youri::Check::Types qw/Date Duration/;

extends 'Youri::Check::Test';

has 'max' => (
    is      => 'rw',
    isa     => Duration,
    coerce  => 1,
    default => sub { DateTime::Duration->new(years => 1) }
);
has 'now' => (
    is      => 'ro',
    isa     => Date,
    default => sub { DateTime->from_epoch(epoch => time()) }
);

our $MONIKER = 'Age';

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Age object.

Specific parameters:

=over

=item max $age

Maximum age allowed (default: 1 year)

=back

=cut

sub run {
    my ($self, $media)  = @_;
    croak "Not a class method" unless ref $self;

    my $max_age =
        $media->get_option($self->get_id(), 'max') ||
        $self->get_max();

    my $database = $self->get_database();
    my $now      = $self->get_now();
    my $verbosity = $self->get_verbosity();
    my $format   = DateTime::Format::Duration->new(
        pattern => '%Y years, %m months, %e days'
    );

    my $check = sub {
        my ($package) = @_;

        my $buildtime = DateTime->from_epoch(
            epoch => $package->get_age()
        );
        
        my $age = $now->subtract_datetime($buildtime);

        my $error;
        if (DateTime::Duration->compare($age, $max_age) > 0) {
            $database->add_rpm_result(
                $MONIKER, $media, $package,
                {
                    buildtime => $buildtime->strftime("%a %d %b %G")
                }
            );
            $error = 1;
        }

        if ($verbosity > 1) {
            printf
                "checking package $package: %s -> %s\n",
                $format->format_duration_from_deltas($format->normalize($age)),
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
