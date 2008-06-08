# $Id$
package Youri::Check::Report::File::Format::RSS;

=head1 NAME

Youri::Check::Report::File::Format::RSS - RSS format support for files

=head1 DESCRIPTION

This report format plugin provides RSS format support for files.

=cut

use warnings;
use strict;
use Carp;
use XML::RSS;
use base 'Youri::Check::Report::File::Format';

sub get_extension {
    return 'rss';
}

sub init_report {
    my ($self, $title, $descriptor, $type) = @_;
    croak "Not a class method" unless ref $self;

    $self->{_cell_values} =
        map { $_->get_value() }
        $descriptor->get_cells();
    $self->{_type} = $type;

    $self->{_rss} = XML::RSS->new(version => '2.0');
    $self->{_rss}->channel(
        title       => $title,
        description => $title,
        language    => 'en',
        ttl         => 1440
    );
}

sub add_results {
    my ($self, $results) = @_;
    
    foreach my $result (@{$results}) {
        if ($self->{_type} eq 'updates') {
            $self->{_rss}->add_item(
                title       => "$result->{source_package} $result->{available} is available",
                description => "Current version is $result->{current}",
                link        => $result->{url} ?
                    $result->{url} : $result->{source},
                guid => "youri-updates-$result->{source_package}-$result->{available}"
            );
        } elsif ($self->{_type} eq 'age') {
           $self->{_rss}->add_item(
                title       => "$result->{source_package} ($result->{arch}) is too old",
                description => "The package was not rebuilt since $result->{buildtime}",
                guid => "youri-age-$result->{source_package}-$result->{buildtime}"
            );
        } elsif ($self->{_type} eq 'rpmcheck') {
           $self->{_rss}->add_item(
                title       => "$result->{package} ($result->{arch}) can not be installed",
                description => "$result->{reason}",
                guid => "youri-rpmcheck-$result->{package}-$result->{arch}"
            );
        } else {
            $self->{_rss}->add_item(
                title       => "[$self->{_type}] $result->{source_package}",
                description => join(
                    "\n",
                    (map { $result->{$_} || '' } @{$self->{_cells_values}}
                    )),
                link        => $result->{url},
                guid        => "youri-$self->{_type}-$result->{source_package}"
            );
        }
    }

}

sub get_content {
    my ($self) = @_;

    return \$self->{_rss}->as_string();
}


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2007, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
