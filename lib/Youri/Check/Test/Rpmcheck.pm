# $Id$
package Youri::Check::Test::Rpmcheck;

=head1 NAME

Youri::Check::Test::Rpmcheck - Check package dependencies with rpmcheck

=head1 DESCRIPTION

This plugins checks package dependencies with rpmcheck, and reports output.

=cut

use Moose::Policy 'Moose::Policy::FollowPBP';
use Moose;
use Carp;
use File::Temp qw/tempdir/;
use Youri::Types qw/ExecutableFile/;

extends 'Youri::Check::Test';

our $MONIKER = 'Rpmcheck';

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Rpmcheck object.

Specific parameters:

=over

=item path $path

Path to the rpmcheck executable (default: /usr/bin/rpmcheck)

=back

=cut

has 'path' => (
    is      => 'rw',
    isa     => ExecutableFile,
    default => '/usr/bin/rpmcheck'
);

sub prepare {
    my ($self, @medias) = @_;
    croak "Not a class method" unless ref $self;

    $self->{_hdlists} = tempdir(CLEANUP => 1);

    foreach my $media (@medias) {
        # uncompress hdlist, as rpmcheck does not handle them
        my $media_id = $media->get_id();
        my $hdlist = $media->get_hdlist();
        system("zcat $hdlist 2>/dev/null > $self->{_hdlists}/$media_id");
    }
}


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

    # then run rpmcheck
    my $database = $self->get_database();

    my $command = "$self->{_path} -explain -failures";
    my $allowed_ids = $media->get_option($self->{_id}, 'allowed');
    my $id = $media->get_id();
    foreach my $allowed_id (@{$allowed_ids}) {
        if ($allowed_id eq $id) {
            carp "incorrect value in $self->{_id} allowed option for media $id: media self-reference";
            next;
        }
        $command .= " -base $self->{_hdlists}/$allowed_id";
    }
    $command .= " <$self->{_hdlists}/$id 2>/dev/null";

    open(my $input, '-|', $command) or croak "Can't run $command: $!";
    my $package_pattern = qr/^
        (\S+) \s
        \(= \s \S+\):
        \s FAILED
        $/x;
    my $reason_pattern  = qr/^
        \s+
        \S+ \s
        \([^)]+\) \s
        (depends \s on|conflicts \s with) \s
        (\S+ (?:\s \([^)]+\))?) \s
        \{([^}]+)\}
        (?: \s on \s file \s (\S+))?
        $/x;
    my $line;
    PACKAGE: while ($line = <$input>) {
        if ($line !~ $package_pattern) {
            chomp $line;
            warn "'$line' doesn't conform to expected format";
            next PACKAGE;
        }
        my $name = $1;
        my $package = $packages->{$name};
        my $arch = $package->get_arch();
        # skip next line
        $line = <$input>;
        # fetch all reasons
        my @reasons;
        REASON: while ($line = <$input>) {
            if ($line =~ /^\s+/) {
                push(@reasons, $line);
            } else {
                last REASON;
            }
        }

        # check first reason
        if ($reasons[0] !~ $reason_pattern) {
            chomp $reasons[0];
            warn "'$reasons[0]' doesn't conform to expected format, skipping";
        } else {
            my $problem = $1;
            my $dependency = $2;
            my $status = $3;
            my $file = $4;

            # analyse problem
            my $reason;
            if ($problem eq 'depends on') {
                if ($status eq 'NOT AVAILABLE') {
                    $reason = "$dependency is missing";
                } else {
                    $reason = "$dependency is not installable";
                    if ($reasons[-1] !~ $reason_pattern) {
                        warn "$reasons[-1] doesn't conform to expected format";
                    } else {
                        $problem = $1;
                        $status = $3;
                    }
                }
            } else {
                $reason = $file ?
                    "implicit conflict with $dependency on file $file" :
                    "explicit conflict with $dependency";
            }

            $database->add_package_result(
                $MONIKER, $media, $package,
                { 
                    arch   => $arch,
                    rpm   => $name,
                    error => $reason
                }
            );
        }

        # restart loop
        redo PACKAGE if $line;
    }
    close $input;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
