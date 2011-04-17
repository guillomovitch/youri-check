# $Id: /mirror/youri/soft/check/trunk/lib/Youri/Check/Test/Updates/Source/Media/Mandriva.pm 1449 2007-01-11T17:11:31.936945Z pterjan  $
package Youri::Check::Test::Updates::Source::Media::Mandriva;

=head1 NAME

Youri::Check::Test::Updates::Source::Mandriva - Mandriva updates source

=head1 DESCRIPTION

This source plugin for L<Youri::Check::Test::Updates> collects updates
available from Mandriva.

=cut

use warnings;
use strict;
use Carp;
use base 'Youri::Check::Test::Updates::Source::Media';

=head2 new(%args)

Creates and returns a new Youri::Check::Test::Updates::Source::Media::Mandriva object.

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
                    'hdlist' => 'http://ftp.free.fr/pub/Distributions_Linux/MandrivaLinux/devel/cooker/SRPMS/main/release/media_info/hdlist.cz',
                    'name' => 'main',
                    'type' => 'source'
                },
                'class' => 'Youri::Media::URPM'
            },
            'contrib.sources' => {
                'options' => {
                    'hdlist' => 'http://ftp.free.fr/pub/Distributions_Linux/MandrivaLinux/devel/cooker/SRPMS/contrib/release/media_info/hdlist.cz',
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
    return "http://svn.mandriva.com/viewvc/packages/cooker/$name/";
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2011, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
