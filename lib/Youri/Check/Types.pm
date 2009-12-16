# $Id$
package Youri::Check::Types;

=head1 NAME

Youri::Check::Types - Types for youri-check

=head1 DESCRIPTION

This class defines somes global types for use in youri applications.

=cut

# predeclare our own types
use MooseX::Types 
    -declare => [qw(
        Date DurationFormat
        BuildSource HashRefOfBuildSources
        UpdatesSource HashRefOfUpdatesSources
    )];

# import builtin types
use MooseX::Types::Moose qw/Str HashRef/;

# class types
class_type Date,           { class => 'DateTime' };
class_type DurationFormat, { class => 'DateTime::Format::Duration' };
class_type UpdatesSource,  { class => 'Youri::Check::Test::Updates::Source' };
class_type BuildSource,    { class => 'Youri::Check::Test::Build::Source' };

# collection types
subtype HashRefOfUpdatesSources,
    as HashRef[UpdatesSource];

subtype HashRefOfBuildSources,
    as HashRef[BuildSource];

# coercion rules
coerce HashRefOfUpdatesSources,
    from HashRef[HashRef],
    => via {
        my $in = $_;
        my $out;
        foreach my $key (keys %$in) {
            $out->{$key} = Youri::Factory->create_from_configuration(
                'Youri::Check::Test::Updates::Source',
                $in->{$key},
                {id => $key}
            )
        }
        return $out;
    };

coerce HashRefOfBuildSources,
    from HashRef[HashRef],
    => via {
        my $in = $_;
        my $out;
        foreach my $key (keys %$in) {
            $out->{$key} = Youri::Factory->create_from_configuration(
                'Youri::Check::Test::Build::Source',
                $in->{$key},
                {id => $key}
            )
        }
        return $out;
    };

coerce DurationFormat,
    from Str,
    via { DateTime::Format::Duration->new(pattern => $_) };

1;
