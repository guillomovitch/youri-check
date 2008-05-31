# $Id$
package Youri::Check::Database;

=head1 NAME

Youri::Check::Database - Result database

=head1 DESCRIPTION

This is the youri-check result database.

=cut

use warnings;
use strict;
use Carp;
use Scalar::Util qw/blessed/;
use Youri::Check::Schema;

=head1 CLASS METHODS

=head2 new(%hash)

Creates and returns a new Youri::Check::Database object.

=cut

sub new {
    my $class   = shift;
    my %options = (
        driver   => '', # driver
        base     => '', # base
        port     => '', # port
        user     => '', # user
        pass     => '', # pass
        test     => 0,     # test mode
        verbose  => 0,     # verbose mode
        parallel => 0,     # parallel mode
        resolver => undef, # maintainer resolver, 
        @_
    );

     croak "No driver defined" unless $options{driver};
    croak "No base defined" unless $options{base};

    my $datasource = "DBI:$options{driver}:dbname=$options{base}";
    $datasource .= ";host=$options{host}" if $options{host};
    $datasource .= ";port=$options{port}" if $options{port};

    my $schema = Youri::Check::Schema->connect(
        $datasource,
        $options{user},
        $options{pass},
        {
            RaiseError => 1,
            PrintError => 0,
            AutoCommit => 1
        }
    ) or croak "Unable to connect: $DBI::errstr";

    my $self = bless {
        _test     => $options{test},
        _verbose  => $options{verbose},
        _parallel => $options{parallel},
        _resolver => $options{resolver},
        _schema   => $schema
    }, $class;

    return $self;
}

=head1 INSTANCE METHODS

=head2 set_resolver()

Set L<Youri::Check::Maintainer::Resolver> object used to resolve package
maintainers.

=cut

sub set_resolver {
    my ($self, $resolver) = @_;
    croak "Not a class method" unless ref $self;

    croak "resolver should be a Youri::Check::Maintainer::Resolver object"
        unless blessed $resolver &&
        $resolver->isa("Youri::Check::Maintainer::Resolver");

    $self->{_resolver} = $resolver;
}

=head2 clone()

Clone resultset object.

=head2 reset()

Reset resultset object, by deleting all contained results.

=head2 add_result($type, $media, $package, $values)

Add given hash reference as a new result for given type and L<Youri::Package> object.

=head2 get_maintainers()

Returns the list of all maintainers with results.

=head2 get_iterator($id, $sort, $filter)

Returns a L<Youri::Check::Resultset::Iterator> object over results for given input it, with optional sort and filter directives.

sort must be an arrayref of column names, such as [ 'package' ].

filter must be a hashref of arrayref of acceptables values indexed by column names, such as { level => [ 'warning', 'error'] }.

=head1 SUBCLASSING

All instances methods have to be implemented.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
