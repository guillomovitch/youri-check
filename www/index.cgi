#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use CGI::Pretty;
use DateTime;
use Youri::Check::Database;

my $database = Youri::Check::Database->new(
    driver => 'SQLite',
    base => '/home/guillaume/my.db'
);

my @test_runs = $database->get_test_runs();
my @maintainers = $database->get_maintainers();

my $cgi = CGI->new();
print $cgi->header(-charset=>'utf-8');

my $page = $cgi->param('page');
if ($page) {
    if ($page eq 'test') {
        test_page();
    } elsif ($page eq 'maintainer') {
        maintainer_page();
    } else {
        index_page();
    }
} else {
    index_page();
}
print $cgi->end_html;

sub test_page {
    my $test =  $cgi->param('test');
    die unless $test;

    my $title = "$test report";
    display_title($title);

}

sub index_page {

    my $title = "QA report";
    display_title($title);

    print $cgi->h2('Global reports');
    print $cgi->ul(
        $cgi->li([ map {
                $_->name() .
                ' (' . DateTime->from_epoch(epoch => $_->date())->ymd() . ')'
            } @test_runs ])
    );
    print $cgi->h2('Individual reports');
    print $cgi->ul(
        $cgi->li(\@maintainers)
    );
}

sub display_title {
    my ($title) = @_;

    print $cgi->start_html($title);
    print $cgi->h1({-style => 'text-align: center'}, $title);
}
