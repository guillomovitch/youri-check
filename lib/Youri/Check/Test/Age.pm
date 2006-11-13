# $Id$
package Youri::Check::Test::Age;

=head1 NAME

Youri::Check::Test::Age - Check maximum age

=head1 DESCRIPTION

This plugin checks packages age, and report the ones exceeding maximum limit.

=cut

use warnings;
use strict;
use Carp;
use DateTime;
use DateTime::Format::Duration;
use base 'Youri::Check::Test';

my $descriptor = Youri::Check::Descriptor::Row->new(
    cells => [
        Youri::Check::Descriptor::Cell->new(
            name        => 'package',
            description => 'package',
            mergeable   => 1,
            value       => 'package',
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
            name        => 'build time',
            description => 'build time',
            mergeable   => 0,
            value       => 'buildtime',
            type        => 'string',
        )
    ]
);

sub get_descriptor {
    return $descriptor;
}

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Age object.

Specific parameters:

=over

=item max $age

Maximum age allowed (default: 1 year)

=item pattern $pattern

Pattern used to describe age (default: %Y year)

=back

=cut

sub _init {
    my $self    = shift;
    my %options = (
        max     => '1 year',
        pattern => '%Y year',
        @_
    );

    $self->{_format} = DateTime::Format::Duration->new(
        pattern => $options{pattern}
    );

    $self->{_now} = DateTime->from_epoch(
        epoch => time()
    );

    $self->{_max_age} = $options{max_age};
}

sub run {
    my ($self, $media, $resultset) = @_;
    croak "Not a class method" unless ref $self;

    my $max_age_string =
        $media->get_option($self->{_id}, 'max') || $self->{_max};

    my $max_age = $self->{_format}->parse_duration($max_age_string);

    my $check = sub {
        my ($package) = @_;

        my $buildtime = DateTime->from_epoch(
            epoch => $package->get_age()
        );
        
        my $age = $self->{_now}->subtract_datetime($buildtime);

        if (DateTime::Duration->compare($age, $max_age) > 0) {
            my $date = $buildtime->strftime("%a %d %b %G");

            $resultset->add_result($self->{_id}, $media, $package, {
                arch      => $package->get_arch(),
                buildtime => $date
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
