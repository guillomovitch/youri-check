# $Id: Conflicts.pm 533 2005-10-20 07:08:03Z guillomovitch $
package Youri::Check::Input::MandrivaConflicts;

=head1 NAME

Youri::Check::Input::MandrivaConflicts - Check file conflicts on Mandriva

=head1 DESCRIPTION

This class checks file conflicts between packages, taking care of Mandriva
packaging policy.

=cut

use warnings;
use strict;
use Carp;
use Youri::Package;
use base 'Youri::Check::Input::Conflicts';

sub _directory_duplicate_exception {
    my ($self, $package1, $package2, $file) = @_;

    # allow shared directories between devel packages of different arch
    return 1 if _multiarch_exception($package1, $package2);

    # allow shared modules directories between perl packages
    return 1 if 
        $file->[Youri::Package::FILE_NAME] =~ /^\/usr\/lib\/perl5\/vendor_perl\// &&
        $file->[Youri::Package::FILE_NAME] !~ /^(auto|[^\/]+-linux)$/;

    return 0;
}

sub _file_duplicate_exception {
    my ($self, $package1, $package2, $file) = @_;

    # allow shared files between devel packages of different arch
    return 1 if _multiarch_exception($package1, $package2);

    return 0;
}

sub _multiarch_exception {
    my ($package1, $package2) = @_;

    return 1 if
        $package1->get_canonical_name() eq $package2->get_canonical_name()
        && $package1->get_name() =~ /-devel$/
        && $package2->get_name() =~ /-devel$/;

    return 0;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
