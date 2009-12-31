# $Id$
package Youri::Check::Test::Rpmcheck;

=head1 NAME

Youri::Check::Test::Rpmcheck - Check package dependencies with rpmcheck

=head1 DESCRIPTION

This plugins checks package dependencies with rpmcheck, and reports output.

=cut

use Carp;
use File::Temp qw/tempdir/;
use Moose::Policy 'Moose::Policy::FollowPBP';
use Moose;
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
    my $verbosity = $self->get_verbosity();
    my $package_pattern = qr/^
        (\S+) \s
        \([^)]+\): \s
        FAILED
        $/x;
    my $dependency_pattern  = qr/^
        \s+
        \S+ \s
        \([^)]+\) \s
        depends \s on \s
        (
            \S+                            # name
            (?:\s \((?:=|<=|>=) \s \S+\))? # optional version
        ) \s
        \{([^}]+)\}
        $/x;
    my $conflict_pattern  = qr/^
        \s+
        \S+ \s
        \([^)]+\) \s
        conflicts \s with \s
        (
            \S+                             # name
            (?:\s \((?:=|<=|>=) \s \S+\))?  # optional version
        ) \s
        on \s file \s (\S+)
        $/x;

    my $command = $self->get_path() . ' -explain -failures -compressed-input';
    my $allowed_ids = $media->get_option($self->get_id(), 'allowed');
    my $media_id = $media->get_id();
    foreach my $allowed_id (@{$allowed_ids}) {
        if ($allowed_id eq $media_id) {
            carp "incorrect value for media $media_id: self-reference";
            next;
        }
        $command .= ' -base ' . $media->get_hdlist();
    }
    $command .= ' <' . $media->get_hdlist() . ' 2>/dev/null';

    if ($verbosity > 1) {
        print "command: $command\n";
    }

    open(my $input, '-|', $command) or croak "Can't run $command: $!";
    my $line;
    PACKAGE: while ($line = <$input>) {
        chomp $line;
        if ($line !~ $package_pattern) {
            print STDERR "'$line' doesn't conform to expected result format\n";
            next PACKAGE;
        }
        my $name = $1;
        my $package = $packages->{$name};
        my $arch = $package->get_arch();
        # skip next line
        $line = <$input>;

        # analyse reasons
        REASON: while ($line = <$input>) {
            chomp $line;
            if ($line =~ /^\s+/) {
                my $error;
                if ($line =~ $dependency_pattern) {
                    my $dependency = $1;
                    my $status     = $2;

                    if ($status eq 'NOT AVAILABLE') {
                        $error = "$dependency is missing";
                    } else {
                        $error = "$dependency is not installable";
                    }
                } elsif ($line =~ $conflict_pattern) {
                    my $dependency = $1;
                    my $file       = $2;

                    $error = $file ?
                        "implicit conflict with $dependency on file $file" :
                        "explicit conflict with $dependency";
                } else {
                    print STDERR
                        "'$line' doesn't conform to expected reason format\n";
                    $error = 'unexpected issue';
                }

                $database->add_rpm_result(
                    $MONIKER, $media, $package,
                    { 
                        error => $error
                    }
                );

                if ($verbosity > 1) {
                    printf
                        "checking package $package: %s\n", $error
                }
            } else {
                last REASON;
            }
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
