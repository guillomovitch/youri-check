# $Id$
package Youri::Check::Input::Rpmlint;

=head1 NAME

Youri::Check::Input::Rpmlint - Check packages with rpmlint

=head1 DESCRIPTION

This plugins checks packages with rpmlint, and reports output.

=cut

use warnings;
use strict;
use Carp;
use Youri::Check::Descriptor::Row;
use Youri::Check::Descriptor::Cell;
use base 'Youri::Check::Input';

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
            name        => 'file',
            description => 'file',
            mergeable   => 0,
            value       => 'file',
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

Creates and returns a new Youri::Check::Input::Rpmlint object.

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

    my $config = $media->rpmlint_config() ?
        $media->rpmlint_config() :
        $self->{_config};

    my $check = sub {
        my ($file, $package) = @_;

        my $arch = $package->get_arch();
        my $name = $package->get_name();

        my $command = "$self->{_path} -f $config $file";
        open(RPMLINT, "$command |") or die "Can't run $command: $!";
        while (<RPMLINT>) {
            chomp;
            if (/^E: \Q$name\E (.+)/) {
                $resultset->add_result($self->{_id}, $media, $package, { 
                    arch  => $arch,
                    file  => $name,
                    error => $1,
                    level => Youri::Check::Input::ERROR
                });
            } elsif (/^W: \Q$name\E (.+)/) {
                $resultset->add_result($self->{_id}, $media, $package, { 
                    arch  => $arch,
                    file  => $name,
                    error => $1,
                    level => Youri::Check::Input::WARNING
                });
            }
        }
        close(RPMLINT);
    };

    $media->traverse_files($check);
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
