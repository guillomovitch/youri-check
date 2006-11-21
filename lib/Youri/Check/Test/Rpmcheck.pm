# $Id$
package Youri::Check::Test::Rpmcheck;

=head1 NAME

Youri::Check::Test::Rpmcheck - Check package dependencies with rpmcheck

=head1 DESCRIPTION

This plugins checks package dependencies with rpmcheck, and reports output.

=cut

use warnings;
use strict;
use Carp;
 use File::Temp qw/tempdir/;
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
            name        => 'reason',
            description => 'reason',
            mergeable   => 0,
            value       => 'reason',
            type        => 'string',
        )
    ]
);

sub get_descriptor {
    return $descriptor;
}

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Rpmcheck object.

Specific parameters:

=over

=item path $path

Path to the rpmcheck executable (default: /usr/bin/rpmcheck)

=back

=cut


sub _init {
    my $self    = shift;
    my %options = (
        path   => '/usr/bin/rpmcheck',
        @_
    );

    $self->{_path}   = $options{path};
}

sub prepare {
    my ($self, @medias) = @_;
    croak "Not a class method" unless ref $self;

    $self->{_hdlists} = tempdir();

    foreach my $media (@medias) {
        # uncompress hdlist, as rpmcheck does not handle them
        my $media_id = $media->get_id();
        my $hdlist = $media->get_hdlist();
        system("zcat $hdlist 2>/dev/null > $self->{_hdlists}/$media_id");
    }
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

    # then run rpmcheck
    my $command =
        "zcat " . $media->get_hdlist() . " 2>/dev/null |" .
        "$self->{_path} -explain -failures 2>/dev/null";
    my $allowed_ids = $media->get_option($self->{_id}, 'allowed');
    foreach my $allowed_id (@{$allowed_ids}) {
        $command .= " -base $self->{_hdlists}/$allowed_id";
    }
    open(my $input, '-|', $command) or croak "Can't run $command: $!";
    PACKAGE: while (my $line = <$input>) {
        next unless $line =~ /^(\S+) \(= \S+\): FAILED$/o;
        my $name = $1;
        my $package = $packages->{$name};
        my $arch = $package->get_arch();
        # skip next line
        $line = <$input>;
        # read first reason
        $line = <>;
        $line =~ /^ \s+
            \S+ \s
            \([^)]+\) \s
            depends \s on \s
            (\S+) \s
           (?:\(([^)]+)\) \s)?
            \{([^}]+)\}
            $/xo;
        my $dependency = $1;
        my $condition = $2;
        my $status = $3;
        if ($status eq 'NOT AVAILABLE') {
            # an direct dependency is missing
            $resultset->add_result(
                $self->{_id}, $media, $package, { 
                arch    => $arch,
                package => $name,
                reason  => "$dependency " .
                    ($condition ? "($condition) " : '' ) .
                    "is missing"
            });
        } else {
            # a direct dependency is uninstallable
            $resultset->add_result(
                $self->{_id}, $media, $package, { 
                arch    => $arch,
                package => $name,
                reason  => "$status is not installable"
            });

            # exhaust indirect reasons
            while ($status ne 'NOT AVAILABLE') {
                $line = <>;
                $line =~ /^ \s+
                    \S+ \s
                    \([^)]+\) \s
                    depends \s on \s
                    \S+ \s
                   (?:\([^)]+\) \s)?
                    \{([^}]+)\}
                    $/xo;
                $status = $1;
            }
        }
    }
    close $input;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
