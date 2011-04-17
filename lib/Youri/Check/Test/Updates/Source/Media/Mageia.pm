# $Id: /mirror/youri/soft/check/trunk/lib/Youri/Check/Test/Updates/Source/Media/Mageia.pm 1449 2007-01-11T17:11:31.936945Z pterjan  $
package Youri::Check::Test::Updates::Source::Media::Mageia;

=head1 NAME

Youri::Check::Test::Updates::Source::Mageia - Mageia updates source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Updates> collects updates
available from Mageia.

=cut

use warnings;
use strict;
use Carp;
use base 'Youri::Check::Test::Updates::Source::Media';

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates::Source::Media::Mageia object.

Specific parameters:

=over

=item medias

List of Youri::Media for source repositories

=back

=cut

sub _init {
    my $self    = shift;
    my %options = (
        'medias' => {
            'core.sources' => {
                'options' => {
                    'hdlist' => 'http://ftp-stud.hs-esslingen.de/pub/Mirrors/Mageia/distrib/cauldron/SRPMS/core/release/media_info/hdlist.cz',
                    'name' => 'main',
                    'type' => 'source'
                },
                'class' => 'Youri::Media::URPM'
            }
        },
        @_
    );
}

sub _url {
    my ($self, $name) = @_;
    return "http://svnweb.mageia.org/packages/cauldron/$name/";
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2011, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
