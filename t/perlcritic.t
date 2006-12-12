#!/usr/bin/perl
# $Id$

use Test::More;

BEGIN {
    eval {
        use Test::Perl::Critic;
    };
    if($@) {
        plan skip_all => "Test::Perl::Critic not availlable";
    } else {
        all_critic_ok();
    }
}

