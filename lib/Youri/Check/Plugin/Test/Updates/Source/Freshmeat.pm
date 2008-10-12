# $Id$
package Youri::Check::Plugin::Test::Updates::Source::Freshmeat;

=head1 NAME

Youri::Check::Plugin::Test::Updates::Source::Freshmeat - Freshmeat updates 
source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Plugin::Test::Updates> collects updates
available from Freshmeat.

=cut

use Moose::Policy 'Moose::Policy::FollowPBP';
use Moose;
use Youri::Types;
use Carp;
use XML::Twig;
use LWP::UserAgent;

extends 'Youri::Check::Plugin::Test::Updates::Source';

has 'url' => (
    is => 'rw',
    isa => 'Uri',
    default => 'http://download.freshmeat.net/backend/fm-projects.rdf.bz2'
);
has 'preload' => (
    is => 'rw',
    isa => 'Bool',
    default => 0
);

=head2 new(%args)

Creates and returns a new Youri::Check::Plugin::Test::Updates::Source::Freshmeat
object.

Specific parameters:

=over

=item preload true/false

Allows to load full Freshmeat catalogue at once instead of checking each software independantly (default: false)

=back

=cut

sub BUILD {
    my ($self, $params) = @_;

    if ($params{preload}) {
        my $versions;
        
        my $project = sub {
            my ($twig, $project) = @_;
            my $name    = $project->first_child('projectname_short')->text();
            my $version = $project->first_child('latest_release')->first_child('latest_release_version')->text();
            $versions->{$name} = $version;
            $twig->purge();
        };

        my $twig = XML::Twig->new(
           TwigRoots => { project => $project }
        );

        my $command = 'GET '. $self->get_url() . '| bzcat';
        open(my $input, '-|', $command) or croak "Can't run $command: $!\n";
        $twig->parse($input);
        close $input;

        $self->{_versions} = $versions;
    }
}

sub _get_package_version {
    my ($self, $name) = @_;

    if ($self->{_versions}) {
        return $self->{_versions}->{$name};
    } else {
        my $version;

        my $latest_release_version = sub {
            $version = $_[1]->text();
        };

        my $twig = XML::Twig->new(
            TwigRoots => { latest_release_version => $latest_release_version }
        );

        my $url = "http://freshmeat.net/projects-xml/$name";
        
        my $command = "GET $url";
        open(my $input, '-|', $command) or croak "Can't run $command: $!\n";
        # freshmeat answer with an HTML page when project doesn't exist
        $twig->safe_parse($input);
        close $input;

        return $version;
    }
}

sub _get_package_url {
    my ($self, $name) = @_;
    return "http://freshmeat.net/projects/$name";
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
