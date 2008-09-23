# $Id$
package Youri::Check::Plugin::Test::Rpmlint;

=head1 NAME

Youri::Check::Plugin::Test::Rpmlint - Check packages with rpmlint

=head1 DESCRIPTION

This plugins checks packages with rpmlint, and reports output.

=cut

use warnings;
use strict;
use Carp;
use base 'Youri::Check::Plugin::Test';

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
        ),
        Youri::Check::Descriptor::Cell->new(
            name        => 'level',
            description => 'level',
            mergeable   => 0,
            value       => 'level',
            type        => 'string',
        )
    ]
);

sub get_descriptor {
    return $descriptor;
}

=head2 new(%args)

Creates and returns a new Youri::Check::Plugin::Test::Rpmlint object.

Specific parameters:

=over

=item path $path

Path to the rpmlint executable (default: /usr/bin/rpmlint)

=item config $config

Specific rpmlint configuration.

=back

=cut


sub _init {
    my $self    = shift;
    my %options = (
        path   => '/usr/bin/rpmlint', # path to rpmlint
        config => '',                 # default rpmlint configuration
        @_
    );

    $self->{_path}   = $options{path};
    $self->{_config} = $options{config};
}

sub run {
    my ($self, $media, $resultset) = @_;
    croak "Not a class method" unless ref $self;

    # index packages first
    my $packages;
    my $index = sub {
        my ($package) = @_;

        $packages->{$package->get_name()} = $package;
    };

    $media->traverse_headers($index);

    # then run rpmlint
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
        $resultset->add_result($self->{_id}, $media, $package, { 
            arch    => $package->get_arch(),
            package => $name,
            error   => $error,
            level   => $level eq 'E' ? 
                Youri::Check::Plugin::Test::ERROR :
                Youri::Check::Plugin::Test::WARNING
        });
    }

    close $input;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
