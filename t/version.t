#!/usr/bin/perl
# $Id$

use Test::More;
use Youri::Check::Test::Updates;
use strict;

my @differents = (
    [ '3.0.0', '1.0.0' ],
    [ '3.0.0', '1.99.9' ],
    [ '3.0.1', '3.0' ],
    [ '3.0pl1', '3.0' ],
    [ '3.0', '3.0beta1' ],
    [ '3.0', '3.0beta' ],
    [ '3.0', '3.0alpha1' ],
    [ '3.0', '3.0alpha' ],
    [ '3.0', '3.0pre1' ],
    [ '3.0', '3.0pre' ],
    [ '3.0pre', '3.0beta' ],
    [ '3.0beta', '3.0alpha' ],
    [ '1.0.0-p1', '1.0.0RC1' ],
    [ '0.9.7f', '0.9.7e' ],
    [ '10', '9' ],
);

my @equals = (
    [ '1.0.0', '1.0.0' ],
    [ '0.9Beta1', '0.9beta1' ],
    [ '0.9beta1', '0.9 beta 1' ],
    [ '0.3-alpha', '0.3_alpha' ],
    [ '0.02', '.02' ],
    [ '2.0.11', '15aug2000' ],
    [ '2.0.11', '20060401' ],
    [ '20', '20060401' ],
);

plan tests => 2 * @differents + 2 * @equals;

foreach my $different (@differents) {
    ok(
        Youri::Check::Test::Updates::is_newer(
	    $different->[0],
	    $different->[1]
	),
        "$different->[0] is newer as $different->[1]"
    );
    ok(
        !Youri::Check::Test::Updates::is_newer(
	    $different->[1],
	    $different->[0]
	),
        "$different->[1] is older as $different->[0]"
    );
}

foreach my $equal (@equals) {
    ok(
        !Youri::Check::Test::Updates::is_newer(
	    $equal->[0],
	    $equal->[1]
	),
        "$equal->[0] is equal as $equal->[1]"
    );
    ok(
        !Youri::Check::Test::Updates::is_newer(
	    $equal->[1],
	    $equal->[0]
	),
        "$equal->[1] is equal as $equal->[0]"
    );
}
