# $Id$
package Youri::Check::Test::Age;

=head1 NAME

Youri::Check::Test::Age - Check maximum age

=head1 DESCRIPTION

This plugin checks packages age, and report the ones exceeding maximum limit.

=cut

use Carp;
use DateTime;
use DateTime::Format::Duration;
use Moose::Policy 'Moose::Policy::FollowPBP';
use Moose;
use Moose::Util::TypeConstraints;

extends 'Youri::Check::Test';

subtype 'DateTime::Format::Duration'
    => as 'Object'
    => where { $_->isa('DateTime::Format::Duration') };

coerce 'DateTime::Format::Duration'
    => from 'Str'
    => via { DateTime::Format::Duration->new(pattern => $_) };

has 'max'     => (
    is => 'rw',
    isa => 'Str',
    default => '1 year'
);
has 'now'     => (
    is => 'ro',
    isa => 'DateTime',
    default => sub { DateTime->from_epoch(epoch => time()) }
);
has 'format'  => (
    is => 'rw',
    isa => 'DateTime::Format::Duration',
    coerce => 1,
    default => sub { DateTime::Format::Duration->new(pattern => '%Y year') }
);

our $MONIKER = 'Age';

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Age object.

Specific parameters:

=over

=item max $age

Maximum age allowed (default: 1 year)

=item format $format

Format used to describe age (default: %Y year)

=back

=cut

sub run {
    my ($self, $media)  = @_;
    croak "Not a class method" unless ref $self;

    my $max_age_string =
        $media->get_option($self->get_id(), 'max') || $self->get_max();

    my $max_age  = $self->get_format()->parse_duration($max_age_string);
    my $database = $self->get_database();
    my $count    = $self->get_count();
    my $now      = $self->get_now();

    my $check = sub {
        my ($package) = @_;

        my $buildtime = DateTime->from_epoch(
            epoch => $package->get_age()
        );
        
        my $age = $now->subtract_datetime($buildtime);

        if (DateTime::Duration->compare($age, $max_age) > 0) {
            $database->add_package_file_result(
                $MONIKER, $media, $package,
                {
                    buildtime => $buildtime->strftime("%a %d %b %G")
                }
            );
            $count++;
        }
    };

    $media->traverse_headers($check);

    $self->set_count($count);
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
