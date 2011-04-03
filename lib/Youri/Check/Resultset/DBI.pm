# $Id$
package Youri::Check::Resultset::DBI;

=head1 NAME

Youri::Check::Resultset::DBI - DBI-based resultset

=head1 DESCRIPTION

This is a DBI-based L<Youri::Check::Resultset> implementation.

It can be created with any DBI-supported database.

=cut

use warnings;
use strict;
use Carp;
use DBI 1.38;
use base 'Youri::Check::Resultset';

my %tables = (
    source_packages => {
        id         => 'key',
        name       => 'text',
        media      => 'text',
        maintainer => 'text',
    }
);

my %queries = (
    add_source_package =>
        'INSERT INTO source_packages (name, media, maintainer) VALUES (?, ?, ?)',
    get_source_package_id =>
        'SELECT id FROM source_packages WHERE name = ?',
    get_maintainers =>
        'SELECT DISTINCT(maintainer) FROM source_packages WHERE maintainer IS NOT NULL',
);

=head1 CLASS METHODS

=head2 new(%hash)

Creates and returns a new Youri::Check::Resultset::DBI object.

Specific parameters:

=over

=item driver $driver

Use given string as DBI driver.

=item base $base

Use given string as database name.

=item port $port

Use given string as database port.

=item user $user

Use given string as database user.

=item pass $pass

Use given string as database password.

=back

=cut

sub _init {
    my $self    = shift;
    my %options = (
        driver => '', # driver
        base   => '', # base
        port   => '', # port
        user   => '', # user
        pass   => '', # pass
        @_
    );

    croak "No driver defined" unless $options{driver};
    croak "No base defined" unless $options{base};

    my $datasource = "DBI:$options{driver}:dbname=$options{base}";
    $datasource .= ";host=$options{host}" if $options{host};
    $datasource .= ";port=$options{port}" if $options{port};

    $self->{_dbh} = DBI->connect($datasource, $options{user}, $options{pass}, {
        RaiseError => 1,
        PrintError => 0,
        AutoCommit => 1
    }) or croak "Unable to connect: $DBI::errstr";

   $self->{_dbh}->trace($options{verbose} - 1) if $options{verbose} > 1;
   $self->{_dbh}->do("PRAGMA synchronous = 0") if $options{driver} eq "SQLite";
}

sub clone {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    my $clone = bless {
        _test     => $self->{_test},
        _verbose  => $self->{_verbose},
        _resolver => $self->{_resolver},
        _dbh      => $self->{_dbh}->clone()
    }, ref $self;

    return $clone;
}

sub reset {
    my ($self) = @_;
    croak "Not a class method" unless ref $self;

    foreach my $table ($self->_get_tables()) {
        my $query = "DROP TABLE $table";
        $self->{_dbh}->do($query); 
    }

    foreach my $table (keys %tables) {
        $self->_create_table($table, $tables{$table});
    }
}

sub _get_tables {
    my ($self) = @_;

    my $schema;
    if ($self->{_dbh}->{Driver}->{Name} eq 'Pg') {
            $schema = "public";
    }

    my @tables = keys %{$self->{_dbh}->table_info(undef,$schema,undef,'TABLE')->fetchall_hashref('TABLE_NAME')};

    return @tables;
}

sub _get_columns {
    my ($self, $table) = @_;
    # proper way would be to use column_info(), but unfortunatly DBD::SQLite 
    # doesn't support it :(
    return 
        keys
        %{$self->{_dbh}->selectrow_hashref("SELECT * from $table")};
}

sub _create_table {
    my ($self, $name, $fields) = @_;

    my @fields;
    while (my ($name, $type) = each %$fields) {
        my $field = $name;
        if ($type eq 'key') {
            if ($self->{_dbh}->{Driver}->{Name} eq 'SQLite') {
                $field .= ' INTEGER';
            } else { 
                $field .= ' SERIAL';
            }
            $field .= ' PRIMARY KEY';
        } elsif ($type eq 'keyref') {
            $field .= ' INTEGER';
        } elsif ($type eq 'text') {
            $field .= ' TEXT';
        } else {
            croak "Unknown field type $type";
        }
        push(@fields, $field);
    }
    my $query = "CREATE TABLE $name (" .  join(',', @fields) .  ")";
    $self->{_dbh}->do($query);
}

sub add_result {
    my ($self, $type, $media, $package, $values) = @_;
    croak "Not a class method" unless ref $self;
    croak "No type defined" unless $type;
    croak "No package defined" unless $package;
    croak "No values defined" unless $values;

    my $key = "add_$type";
    my $sth = $self->{_sths}->{$key};

    unless ($sth) {
        my @fields = keys %$values;
        $self->_create_table($type, {
            'source_package_id' => 'keyref',
            map { $_ => 'text' } @fields
        });
        my $query = "INSERT INTO $type (" .
           join(',', 'source_package_id', @fields) .
          ") VALUES (" .
           join(',', '?', map { '?' } @fields) .
          ")";
        $sth = $self->{_dbh}->prepare($query);
        $self->{_sths}->{$key} = $sth;
    }

    print "adding result for type $type and package $package\n"
        if $self->{_verbose} > 1;

    $sth->execute(
        $self->_get_source_package_id(
            $package->get_canonical_name(),
            $media->get_name(),
        ),
        values %$values
    );
}

sub get_types {
    my ($self) = @_;

    return
        grep { ! $tables{$_} }
        $self->_get_tables();
}

sub get_maintainers {
    my ($self) = @_;

    return $self->_get_multiple_values('get_maintainers');
}

sub get_iterator {
    my ($self, $id, $sort, $filter) = @_;

    croak 'No id given, aborting'
        unless $id;
    croak 'sort should be an arrayref'
        if $sort and ref $sort ne 'ARRAY';
    croak 'filter should be an hashref'
        if $filter and ref $filter ne 'HASH';
        
    my $query = $self->_get_iterator_query($id, $sort, $filter);

    my $sth = $self->{_dbh}->prepare($query);
    $sth->execute();

    return Youri::Check::Resultset::DBI::Iterator->new($sth);
}

sub _get_iterator_query {
    my ($self, $table, $sort, $filter) = @_;

    my @fields =
        grep { ! /source_package_id/ }
        $self->_get_columns($table);

    my $query = "SELECT DISTINCT " .
        join(',', 'name as source_package', 'media', 'maintainer', @fields) .
        " FROM $table, source_packages" .
        " WHERE source_packages.id = $table.source_package_id";

    if ($filter) {
        foreach my $column (keys %{$filter}) {
            foreach my $value (@{$filter->{$column}}) {
                $query .= " AND $column = " . $self->{_dbh}->quote($value);
            }
        }
    }

    if ($sort) {
        $query .= " ORDER BY " . join(', ', @{$sort});
    }

    return $query;
}

sub _get_source_package_id {
    my ($self, $package, $media) = @_;

    my $id = $self->_get_single_value(
        'get_source_package_id',
        $package
    );
    $id = $self->_add_source_package($package, $media) unless $id;

    return $id;
}

sub _add_source_package {
    my ($self, $package, $media) = @_;

    my $maintainer = $self->{_resolver} ? 
        $self->{_resolver}->get_maintainer($package) :
        undef;

    # lock tables to ensure proper isolation
    $self->{_dbh}->do('LOCK TABLES source_packages WRITE') if $self->{_parallel};

    my $sth =
        $self->{_sths}->{add_source_package} ||=
        $self->{_dbh}->prepare($queries{add_source_package});

    $sth->execute(
        $package,
        $media,
        $maintainer
    );

    my $id = $self->{_dbh}->last_insert_id(undef, undef, 'source_packages', 'id');

    # unlock table
    $self->{_dbh}->do('UNLOCK TABLES') if $self->{_parallel};

    return $id;
}

sub _get_single_value {
    my ($self, $query, @values) = @_;

    my $sth =
        $self->{_sths}->{$query} ||=
        $self->{_dbh}->prepare($queries{$query});

    $sth->execute(@values);

    my @row = $sth->fetchrow_array();
    return @row ? $row[0]: undef;
}

sub _get_multiple_values {
    my ($self, $query, @values) = @_;

    my $sth =
        $self->{_sths}->{$query} ||=
        $self->{_dbh}->prepare($queries{$query});

    $sth->execute(@values);

    my @results;
    while (my @row = $sth->fetchrow_array()) {
        push @results, $row[0];
    }
    return @results;
}

# close database connection
sub DESTROY {
    my ($self) = @_;

    foreach my $sth (values %{$self->{_sths}}) {
        $sth->finish() if $sth;
    }

    # warning, may be called before _dbh is created
    $self->{_dbh}->disconnect() if $self->{_dbh};
}

package Youri::Check::Resultset::DBI::Iterator;

sub new {
    my ($class, $sth) = @_;

    my $self = bless {
        _sth    => $sth,
        _queue  => []
    }, $class;

    return $self;
}

sub has_results {
    my ($self) = @_;

    return 1 if @{$self->{_queue}};

    push(
        @{$self->{_queue}},
        $self->{_sth}->fetchrow_hashref()
    );
    
    return defined $self->{_queue}->[-1];
}

sub get_result {
    my ($self) = @_;
    
    return @{$self->{_queue}} ?
        shift @{$self->{_queue}}:
        $self->{_sth}->fetchrow_hashref();
}

sub DESTROY {
    my ($self) = @_;
    $self->{_sth}->finish();
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
