#!/usr/bin/perl
# $Id$

use Test::More;

BEGIN {
    eval {
        require Test::Distribution;
    };
    if($@) {
        plan skip_all => 'Test::Distribution not installed';
    } else {
        import Test::Distribution only => [ qw/use pod description/ ];
    }
}
