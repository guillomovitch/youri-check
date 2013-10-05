# $Id: /mirror/youri/soft/check/trunk/lib/Youri/Check/Test/Updates/Source/Media/Rosa.pm 1449 2007-01-11T17:11:31.936945Z pterjan  $
package Youri::Check::Test::Updates::Urpmi::Media::Rosa;

=head1 NAME

Youri::Check::Test::Updates::Urpmi::Rosa - Rosa updates source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Updates> collects updates
available from Rosa.

=cut

use warnings;
use strict;
use Carp;
use base 'Youri::Check::Test::Updates::Urpmi::Media';

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates::Urpmi::Media::Rosa object.

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
            'main.sources' => {
                'options' => {
                    'hdlist' => 'http://abf.rosalinux.ru/downloads/rosa2012.1/repository/SRPMS/main/release/media_info/hdlist.cz',
                    'name' => 'main',
                    'type' => 'source'
                },
                'class' => 'Youri::Media::URPM'
            },
            'contrib.sources' => {
                'options' => {
                    'hdlist' => 'http://abf.rosalinux.ru/downloads/rosa2012.1/repository/SRPMS/contrib/release/media_info/hdlist.cz',
                    'name' => 'contrib',
                    'type' => 'source'
                },
                'class' => 'Youri::Media::URPM'
            }
        },
        @_
    );
    $self->SUPER::_init(%options);
}

sub _url {
    my ($self, $name) = @_;
    return "https://abf.rosalinux.ru/import/$name";
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2013, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
