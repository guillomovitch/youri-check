# $Id$
package Youri::Check::Report;

=head1 NAME

Youri::Check::Report - Abstract output plugin

=head1 DESCRIPTION

This abstract class defines report plugin interface.

=cut

use Moose;
use Carp;
use UNIVERSAL::require;

extends 'Youri::Check::Plugin';

has 'global'     => (is => 'rw', isa => 'Bool', reader => 'is_global');
has 'individual' => (is => 'rw', isa => 'Bool', reader => 'is_individual');
has 'config'     => (is => 'rw', isa => 'HashRef');

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

=head1 INSTANCE METHODS

=head2 run($resultset)

Reports the result stored in given L<Youri::Check::Resultset> object.

=cut

sub run {
    my ($self, $resultset) = @_;

    $self->_init_report();

    # get types and maintainers list from resultset
    my @maintainers = $resultset->get_maintainers();
    my @test_ids    = $resultset->get_types();

    foreach my $test_id (@test_ids) {
        # get test configuration
        my $test_config = $self->{_config}->get_param('tests')->{$test_id};

        if (! $test_config) {
            carp "No configuration available for test $test_id, skipping";
            next;
        }

        my $test_class = $test_config->{class};
        $test_class->require();
        my $test_descriptor = $test_class->get_descriptor();

        my $test_filter = $test_config->{options}->{filter};

        if ($self->{_global}) {
            print "generating $test_id global report\n"
                if $self->{_verbose};
            $self->_global_report(
                $resultset,
                $test_id,
                $test_descriptor,
                $test_filter
            );
        }

        if ($self->{_individual}) {
            # skip non-relevant tests
            next unless $test_descriptor->has_cell('maintainer');
            # remove redundant columns
            my $test_descriptor_light = $test_descriptor->clone();
            $test_descriptor_light->drop_cell('maintainer');

            foreach my $maintainer (@maintainers) {
                print "generating $test_id individual report for $maintainer\n"
                    if $self->{_verbose};
                $self->_individual_report(
                    $resultset,
                    $test_id,
                    $test_descriptor_light,
                    $test_filter,
                    $maintainer,
                );
            }
        }
    }

    $self->_finish_report(\@test_ids, \@maintainers);
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
