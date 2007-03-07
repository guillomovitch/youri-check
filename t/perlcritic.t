#!/usr/bin/perl
# $Id$

use Test::More;
use File::Basename;
use File::Spec;


BEGIN {
    eval {
        use Test::Perl::Critic;
    };
    if($@) {
        plan skip_all => "Test::Perl::Critic not available";
    } else {
        my $libdir = File::Spec->catdir(
            dirname($0),
            File::Spec->updir(),
            'lib'
        );
        all_critic_ok($libdir);
    }
}

