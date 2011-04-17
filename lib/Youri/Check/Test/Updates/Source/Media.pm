# $Id: /mirror/youri/soft/check/trunk/lib/Youri/Check/Test/Updates/Source/Media.pm 1449 2007-01-11T17:11:31.936945Z pterjan  $
package Youri::Check::Test::Updates::Source::Media;

=head1 NAME

Youri::Check::Test::Updates::Source::Media - Youri::Media distribution updates source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Updates> collects updates
available from Youri::Media supported distribution.
You should subclass it to get links and correct default URL.

=cut

use warnings;
use strict;
use Carp;
use Youri::Utils;
use base 'Youri::Check::Test::Updates::Source';

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates::Source::Media object.

Specific parameters:

=over

=item medias

List of source medias

=back

=cut

sub _init {
    my $self    = shift;
    my %options = (
        medias => [],
        @_
    );

    my @medias;
    use Data::Dumper;
    print Dumper($options{'medias'});
    $self->{_srcs} = [];
    foreach my $id (keys %{$options{'medias'}}) {
        my $media_conf = $options{'medias'}->{$id};
	my $media;
        next unless $media_conf->{'options'}{'type'} eq 'source';
        eval {
	    $media = create_instance(
                    'Youri::Media',
                    $media_conf,
                    {
                        id      => $id,
                    }
                );
            push(@medias, $media);
        };
	if ($@) {
            print STDERR "Failed to create media $id: $@\n";
	    next;
        }
        print STDERR "Indexing media $id packages\n" if $self->{_verbose};

        my $index = sub {
            my ($package) = @_;
            $self->{_versions}->{$package->get_name()} = $package->get_version();
        };

        $media->traverse_headers($index);
    }
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2011, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
