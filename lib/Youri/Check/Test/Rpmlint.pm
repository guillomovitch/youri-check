# $Id$
package Youri::Check::Test::Rpmlint;

=head1 NAME

Youri::Check::Test::Rpmlint - Check packages with rpmlint

=head1 DESCRIPTION

This plugins checks packages with rpmlint, and reports output.

=cut

use Carp;
use Moose;
use MooseX::FollowPBP;
use Youri::Types qw/ExecutableFile ReadableFile/;

extends 'Youri::Check::Test';

our $MONIKER = 'Rpmlint';

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Rpmlint object.

Specific parameters:

=over

=item path $path

Path to the rpmlint executable (default: /usr/bin/rpmlint)

=item config $config

Specific rpmlint configuration.

=back

=cut

has 'path' => (
    is      => 'rw',
    isa     => ExecutableFile,
    default => '/usr/bin/rpmlint'
);

has 'config' => (
    is      => 'rw',
    isa     => ReadableFile
);

sub run {
    my ($self, $media) = @_;
    croak "Not a class method" unless ref $self;

    # index packages first
    my $packages;
    my $index = sub {
        my ($package) = @_;

        $packages->{$package->get_name()} = $package;
    };

    $media->traverse_headers($index);

    # then run rpmlint
    my $database = $self->get_database();

    my $config =
        $media->get_option($self->{_id}, 'config') || $self->{_config};

    my $command =
        $self->{_path} . ' ' .
        ($config ? "-f $config " : '' ) . 
        $media->get_path() .
        ' 2>/dev/null';

    open(my $input, '-|', $command) or croak "Can't run $command: $!";
    my $pattern = qr/^([EW]): (\S+) (.+)$/;

    # results for each packages will be given consecutively
    # keeping track of previous package should allow to spare
    # many hash lookup
    my $last_name;
    my $last_package;
    while (my $line = <$input>) {
        next unless $line =~ $pattern;
        my $level = $1;
        my $name  = $2;
        my $error = $3;
        my $package;
        if ($name eq $last_name) {
            $package = $last_package;
        } else {
            $package = $packages->{$name};
            $last_name = $name;
            $last_package = $package;
        }
        $database->add_package_result(
            $MONIKER, $media, $package, 
            {
                error   => $error,
                level   => $level eq 'E' ? 
                    Youri::Check::Test::ERROR :
                    Youri::Check::Test::WARNING
            }
        );
    }

    close $input;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
