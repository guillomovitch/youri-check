# $Id$
package Youri::Check::Database;

=head1 NAME

Youri::Check::Database - Result database

=head1 DESCRIPTION

This is the youri-check result database.

=cut

use Carp;
use Moose::Policy 'Moose::Policy::FollowPBP';
use Moose;
use MooseX::Types::Moose qw/Str Bool Int/;
use Scalar::Util qw/blessed/;
use Youri::Check::Schema;

=head1 CLASS METHODS

=head2 new(%hash)

Creates and returns a new Youri::Check::Database object.

=cut

has 'dsn' => (
    is      => 'ro',
    isa     => Str,
    required => 1
);
has 'user' => (
    is      => 'ro',
    isa     => Str,
);
has 'pass' => (
    is      => 'ro',
    isa     => Str,
);
has 'schema'  => (
    is       => 'rw',
    isa      => 'Youri::Check::Schema',
);
has 'parallel' => (
    is      => 'ro',
    isa     => Bool,
);
has 'verbosity' => (
    is      => 'rw',
    isa     => Int,
    default => 0
);
has 'resolver'  => (
    is        => 'rw',
    isa       => 'Youri::Check::Maintainer::Resolver',
    predicate => 'has_resolver'
);
sub BUILD {
    my ($self, $params) = @_;

    my $schema = Youri::Check::Schema->connect(
        $self->get_dsn(),
        $self->get_user(),
        $self->get_pass(),
        {
            RaiseError => 1,
            PrintError => 0,
            AutoCommit => 1
        }
    ) or croak "Unable to connect: $DBI::errstr";

    # deploy schema if needed
    my $dbh = $schema->storage()->dbh();
    $schema->deploy({add_drop_table => 1})
        if ! $dbh->tables(undef, undef, '%', 'TABLE');

    $self->set_schema($schema);
}

=head1 INSTANCE METHODS

=head2 clone()

Clone resultset object.

=cut

sub clone {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    my $clone = bless {
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

    # extend schema
    $self->load($moniker);

    my $schema = $self->get_schema();

    # register test run
    my $last_run = $schema->resultset('TestRun')->single({
        name => $moniker
    });

    if ($last_run) {
        # delete all previous results
        $schema->resultset($moniker)->search()->delete();

        # update test run
        $last_run->date(time());
        $last_run->update();
    } else {
        # create additional tables
        $schema->deploy({
            add_drop_table => 1,
            parser_args => {
                sources => [ $moniker ]
            }
        });

        # create test run
        $schema->resultset('TestRun')->create({
            name => $moniker,
            date => time()
        })->update();
    }
}

sub unregister {
    my ($self, $moniker) = @_;
    croak "Not a class method" unless ref $self;

    # get last run
    my $last_run = $self->get_schema()->resultset('TestRun')->single({
        name => $moniker,
    });

    # update test count
    $last_run->update();
}

sub load {
    my ($self, $moniker) = @_;
    croak "Not a class method" unless ref $self;

    # load the new class
    Youri::Check::Schema->load_classes($moniker);

    # replace current schema with a new clone
    my $schema = Youri::Check::Schema->clone();
    $schema->storage($self->get_schema()->storage());
    $self->set_schema($schema);
}

=head2 add_rpm_result($source, $moniker, $media, $rpm, $values)

Add given hash reference as a new result for given type and L<Youri::Package> object.

=cut

sub add_rpm_result {
    my ($self, $moniker, $media, $rpm, $values) = @_;
    croak "Not a class method" unless ref $self;
    croak "No moniker defined" unless $moniker;
    croak "No media defined" unless $media;
    croak "No rpm defined" unless $rpm;
    croak "No values defined" unless $values;

    print "adding result for test $moniker and rpm $rpm\n"
        if $self->get_verbosity > 1;

    my $rpm_id =
        $self->get_rpm_id($rpm) ||
        $self->add_rpm($media, $rpm);

    my $new_result = $self->get_schema()->resultset($moniker)->create({
        rpm_id => $rpm_id,
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
        if $self->get_verbosity() > 1;

    my $package_id =
        $self->get_package_id($package) ||
        $self->add_package($media, $package);

    $self->get_schema()->resultset($moniker)->create({
        package_id => $package_id,
        %{$values}
    })->update();
}

sub add_section {
    my ($self, $name) = @_;

    return $self->get_schema()->resultset('Section')->create({
        name => $name,
    })->update();
}

sub get_section_id {
    my ($self, $name) = @_;

    my $record = $self->get_schema()->resultset('Section')->single({
        name => $name,
    });

    return $record ? $record->id() : undef;
}

sub add_maintainer {
    my ($self, $name) = @_;

    return $self->get_schema()->resultset('Maintainer')->create({
        name => $name,
    })->update();
}

sub get_maintainer_id {
    my ($self, $name) = @_;

    my $record = $self->get_schema()->resultset('Maintainer')->single({
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
    if ($self->has_resolver()) {
        my $maintainer = $self->get_resolver()->get_maintainer($package);
        if ($maintainer) {
            $maintainer_id =
                $self->get_maintainer_id($maintainer) ||
                $self->add_maintainer($maintainer);
        }
    }

    return $self->get_schema()->resultset('Package')->create({
        name          => $package->get_canonical_name(),
        version       => $package->get_version(),
        release       => $package->get_release(),
        section_id    => $section_id,
        maintainer_id => $maintainer_id
    })->update()->id();
}

sub get_package_id {
    my ($self, $package) = @_;

    my $record = $self->get_schema()->resultset('Package')->single({
        name    => $package->get_canonical_name(),
        version => $package->get_version(),
        release => $package->get_release(),
    });

    return $record ? $record->id() : undef;
}

sub add_rpm {
    my ($self, $media, $package) = @_;

    my $package_id =
        $self->get_package_id($package) ||
        $self->add_package($media, $package);

    return $self->get_schema()->resultset('RPM')->create({
        name       => $package->get_name(),
        arch       => $package->get_arch(),
        package_id => $package_id
    })->update()->id();
}

sub get_rpm_id {
    my ($self, $package) = @_;

    my $record = $self->get_schema()->resultset('RPM')->single({
        name => $package->get_name(),
        arch => $package->get_arch(),
    });

    return $record ? $record->id() : undef;
}

=head2 get_maintainers()

Returns the list of all maintainers with results.

=cut

sub get_maintainers {
    my ($self) = @_;

    return $self->get_schema()->resultset('Maintainer')->all();
}

sub get_tests {
    my ($self) = @_;

    return $self->get_schema()->resultset('TestRun')->all();
}

sub get_test_count {
    my ($self, $test) = @_;

    return $self->get_schema()->resultset($test)->count();
}

sub get_test_results {
    my ($self, $test) = @_;

    return $self->get_schema()->resultset($test)->all();
}


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
