# $Id$
package Youri::Check::Report;

=head1 NAME

Youri::Check::Report - Abstract output plugin

=head1 DESCRIPTION

This abstract class defines output plugin interface.

=cut

use warnings;
use strict;
use Carp;
use Youri::Utils;

=head1 CLASS METHODS

=head2 new(%args)

Creates and returns a new Youri::Check::Report object.

Generic parameters (subclasses may define additional ones):

=over

=item global true/false

Global reports generation (default: true).

=item individual true/false

Individual reports generation (default: true).

=back

Warning: do not call directly, call subclass constructor instead.

=cut

sub new {
    my $class = shift;
    croak "Abstract class" if $class eq __PACKAGE__;

    my %options = (
        id         => '',
        test       => 0,
        verbose    => 0,
        global     => 1,
        individual => 1,
        config     => undef,
        @_
    );

    croak "Neither global nor individual reporting selected" unless $options{global} || $options{individual};

    my $self = bless {
        _id         => $options{id},
        _test       => $options{test},
        _verbose    => $options{verbose},
        _global     => $options{global},
        _individual => $options{individual},
        _config     => $options{config}
    }, $class;

    $self->_init(%options);

    return $self;
}

sub _init {
    # do nothing
}

=head1 INSTANCE METHODS

=head2 get_id()

Returns plugin identity.

=cut

sub get_id {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    return $self->{_id};
}

=head2 run($resultset)

Reports the result stored in given L<Youri::Check::Resultset> object.

=cut

sub run {
    my ($self, $resultset) = @_;

    $self->_init_report();

    # get types and maintainers list from resultset
    my @maintainers = $resultset->get_maintainers();
    my @types       = $resultset->get_types();

    foreach my $type (@types) {
        # get formatting instructions from class
        my $class = $self->{_config}->get($type . '_class');
        load($class);
        my $descriptor = $class->get_descriptor();

        if ($self->{_global}) {
            print STDERR "generating global report for $type\n" if $self->{_verbose};
            $self->_global_report(
                $resultset,
                $type,
                $descriptor
            );
        }

        if ($self->{_individual}) {
            foreach my $maintainer (@maintainers) {
                print STDERR "generating individual report for $type and $maintainer\n" if $self->{_verbose};

                $self->_individual_report(
                    $resultset,
                    $type,
                    $descriptor,
                    $maintainer
                );
            }
        }
    }

    $self->_finish_report(\@types, \@maintainers);
}

sub _init_report {
    # do nothing
}

sub _global_report {
    # do nothing
}

sub _individual_report {
    # do nothing
}

sub _finish_report {
    # do nothing
}

=head1 SUBCLASSING

The following methods have to be implemented:

=over

=item run

As an alternative, the following hooks can be implemented:

=over

=item _init_report

=item _global_report

=item _individual_report

=item _finish_report

=back

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
