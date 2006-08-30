# $Id$
package Youri::Check::Maintainer::Preferences::File;

=head1 NAME

Youri::Check::Maintainer::Preferences::File - File-based maintainer preferences implementation

=head1 DESCRIPTION

This is a file-based L<Youri::Check::Maintainer::Preferences> implementation.

It uses files in maintainer home directories.

=cut

use warnings;
use strict;
use Carp;
use Youri::Config;
use base 'Youri::Check::Maintainer::Preferences';

=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Check::Maintainer::Preferences::File object.

No specific parameters.

=cut

sub get_preference {
    my ($self, $maintainer, $plugin, $value) = @_;
    croak "Not a class method" unless ref $self;
    return unless $maintainer && $plugin && $value;

    print "Retrieving maintainer $maintainer preferences\n"
        if $self->{_verbose} > 0;

    $self->_load_config($maintainer)
        unless exists $self->{_config}->{$maintainer};

    return $self->{_config}->{$maintainer} ?
        $self->{_config}->{$maintainer}->get($plugin . '_' . $value) :
        undef;
}

sub _load_config {
    my ($self, $maintainer) = @_;

    print "Attempting to load maintainers preferences for $maintainer\n" if $self->{_verbose} > 1;


    my ($login) = $maintainer =~ /^(\S+)\@\S+$/;
    my $home = (getpwnam($login))[7];
    my $file = "$home/.youri/check.prefs";

    if (-f $file && -r $file) {
        print "Found, loading\n" if $self->{_verbose} > 1;
        my $config = Youri::Config->new(
            {
                CREATE => 1,
                GLOBAL => {
                   DEFAULT  => undef,
                   EXPAND   => EXPAND_VAR | EXPAND_ENV,
                   ARGCOUNT => ARGCOUNT_ONE,
                }
            }
        );
        $config->file($file);
        $self->{_config}->{$maintainer} = $config;
    } else {
        print "Not found, aborting\n" if $self->{_verbose} > 1;
        $self->{_config}->{$maintainer} = undef;
    }

}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
