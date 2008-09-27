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

    # deploy schema if needed
    my $dbh = $schema->storage()->dbh();
    $schema->deploy({add_drop_table => 1})
        if ! $dbh->tables(undef, undef, '%', 'TABLE');

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

=cut

sub clone {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    my $clone = bless {
        _test     => $self->{_test},
        _verbose  => $self->{_verbose},
        _resolver => $self->{_resolver},
        _schema   => $self->{_dbh}->schema
    }, ref $self;

    return $clone;
}

=head2 reset()

Reset resultset object, by deleting all contained results.

=cut

sub register {
    my ($self, $moniker) = @_;
    croak "Not a class method" unless ref $self;

    # load the new class
    Youri::Check::Schema->load_classes($moniker);

    # replace current schema with a new clone
    my $schema = Youri::Check::Schema->clone();
    $schema->storage($self->{_schema}->storage());
    $self->{_schema} = $schema;

    my $last_run = $self->{_schema}->resultset('TestRun')->single({
        name => $moniker,
    });

    if ($last_run) {
        # delete all previous results
        $self->{_schema}->resultset($moniker)->search()->delete();

        # update test run
        $last_run->date(time());
        $last_run->update();
    } else {
        # create additional tables
        $self->{_schema}->deploy({
            add_drop_table => 1,
            parser_args => {
                sources => [ $moniker ]
            }
        });

        # create test run
        $self->{_schema}->resultset('TestRun')->create({
            name => $moniker,
            date => time()
        })->update();
    }
}

=head2 add_result($source, $media, $package, $values)

Add given hash reference as a new result for given type and L<Youri::Package> object.

=cut

sub add_package_file_result {
    my ($self, $moniker, $media, $package, $values) = @_;
    croak "Not a class method" unless ref $self;
    croak "No moniker defined" unless $moniker;
    croak "No media defined" unless $media;
    croak "No package defined" unless $package;
    croak "No values defined" unless $values;

    print "adding result for test $moniker and package $package\n"
        if $self->{_verbose} > 1;

    my $package_file_id =
        $self->get_package_file_id($package) ||
        $self->add_package_file($media, $package);

    my $new_result = $self->{_schema}->resultset($moniker)->create({
        package_file_id => $package_file_id,
        %{$values}
    });
    $new_result->update();
}

sub add_package_result {
    my ($self, $moniker, $media, $package, $values) = @_;
    croak "Not a class method" unless ref $self;
    croak "No moniker defined" unless $moniker;
    croak "No media defined" unless $media;
    croak "No package defined" unless $package;
    croak "No values defined" unless $values;

    print "adding result for test $moniker and package $package\n"
        if $self->{_verbose} > 1;

    my $package_id =
        $self->get_package_id($package) ||
        $self->add_package($media, $package);

    $self->{_schema}->resultset($moniker)->create({
        package_id => $package_id,
        %{$values}
    })->update();
}

sub add_section {
    my ($self, $name) = @_;

    return $self->{_schema}->resultset('Section')->create({
        name => $name,
    })->update();
}

sub get_section_id {
    my ($self, $name) = @_;

    my $record = $self->{_schema}->resultset('Section')->single({
        name => $name,
    });

    return $record ? $record->id() : undef;
}

sub add_maintainer {
    my ($self, $name) = @_;

    return $self->{_schema}->resultset('Maintainer')->create({
        name => $name,
    })->update();
}

sub get_maintainer_id {
    my ($self, $name) = @_;

    my $record = $self->{_schema}->resultset('Maintainer')->single({
        name => $name,
    });

    return $record ? $record->id() : undef;
}

sub add_package {
    my ($self, $media, $package) = @_;

    my $section = $media->get_name();

    my $section_id =
        $self->get_section_id($section) ||
        $self->add_section($section);


    my $maintainer_id;
    if ($self->{_resolver}) {
        my $maintainer = $self->{_resolver}->resolve($package);
        $maintainer_id =
            $self->get_maintainer_id($maintainer) ||
            $self->add_maintainer($maintainer);
    }

    return $self->{_schema}->resultset('Package')->create({
        name          => $package->get_canonical_name(),
        version       => $package->get_version(),
        release       => $package->get_release(),
        section_id    => $section_id,
        maintainer_id => $maintainer_id
    })->update();
}

sub get_package_id {
    my ($self, $package) = @_;

    my $record = $self->{_schema}->resultset('Package')->single({
        name    => $package->get_canonical_name(),
        version => $package->get_version(),
        release => $package->get_release(),
    });

    return $record ? $record->id() : undef;
}

sub add_package_file {
    my ($self, $media, $package) = @_;

    my $package_id =
        $self->get_package_id($package) ||
        $self->add_package($media, $package);

    return $self->{_schema}->resultset('PackageFile')->create({
        name       => $package->get_name(),
        arch       => $package->get_arch(),
        package_id => $package_id
    })->update();
}

sub get_package_file_id {
    my ($self, $package) = @_;

    my $record = $self->{_schema}->resultset('PackageFile')->single({
        name => $package->get_name(),
        arch => $package->get_arch(),
    });

    return $record ? $record->id() : undef;
}

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
