# $Id$
package Youri::Check::Types;

=head1 NAME

Youri::Check::Types - Global data types

=head1 DESCRIPTION

This class defines somes global data types.

=cut

use Moose;
use Moose::Util::TypeConstraints;
use List::MoreUtils qw(all);
use Regexp::Common qw/URI/;
use UNIVERSAL::require;

subtype 'Directory'
    => as 'Str'
    => where { -d $_ };

subtype 'Uri'
    => as 'Str'
    => where { /^$RE{URI}$/ };

subtype 'HashRef[HashRef]'
    => as 'HashRef'
    => where {
        all {
            ref($_) eq 'HASH'
        } values %$_;
    };

1;
