# $Id: /local/youri/soft/check/trunk/lib/Youri/Check/Test/Rpmlint.pm 2282 2006-11-05T19:12:24.668092Z guillaume  $
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

        next if $media->skip_test($self->{_id});

        print STDERR "Indexing media $media_id packages\n"
            if $self->{_verbose};

        my $index = sub {
            my ($package) = @_;

            $self->{_packages}->{$media_id}->{$package->get_name()} = $package;
        };

        $media->traverse_headers($index);
    }
}


sub run {
    my ($self, $media, $resultset) = @_;
    croak "Not a class method" unless ref $self;

    my $media_id = $media->get_id();
    my $command =
        "zcat " . $media->get_hdlist() . " 2>/dev/null |" .
        "$self->{_path} -explain -failures 2>/dev/null";
    foreach my $other_media_id ($media->allow_deps()) {
        $command .= " -base $self->{_hdlists}/$other_media_id";
    }
    open(my $input, '-|', $command) or croak "Can't run $command: $!";
    PACKAGE: while (my $line = <$input>) {
        next unless $line =~ /^(\S+) \(= \S+\): FAILED$/o;
        my $name = $1;
        # skip next line
        $line = <$input>;
        # read each following line until final missing dependency
        DEPENDENCY: while ($line = <$input>) {
            $line =~ /^ \s+
                (\S+) \s
                \([^)]+\) \s
                depends \s on \s
                (\S+) \s
               (?:\(([^)]+)\) \s)?
                \{([^}]+)\}
                $/xo;
            my $dependency = $2;
            my $condition = $3;
            my $status = $4;
            last DEPENDENCY if $status eq 'NOT AVAILABLE';
        }
        my $package = $self->{_packages}->{$media_id}->{$name};
        my $arch = $package->get_arch();
        $resultset->add_result(
            $self->{_id}, $media, $package, { 
            arch    => $arch,
            package => $name
        });
    }
    close $input;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
