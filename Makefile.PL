# $Id$
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME       => 'youri-check',
    VERSION    => 0.9,
    AUTHOR     => 'Youri project <youri@zarb.org>',
    EXE_FILES  => [ 'bin/youri-check' ],
    PREREQ_PM  => {
        'Youri::Config'          => 0,
        'Youri::Utils'           => 0,
        'Youri::Bugzilla'        => 0,
        'Pod::Simple::HTMLBatch' => 0
    }
);

package MY;

sub post_constants {
    my ($self) = @_;
    my $sysconfdir =
        $self->{ARGS}->{SYSCONFDIR} ||
        ($self->{INSTALLDIRS} eq 'site' ?
            '/usr/local/etc' :
            '/usr/etc');
    return <<EOF;
SYSCONFDIR = $sysconfdir
EOF
}

sub top_targets {
    my ($self) = @_;
    my $top_targets = $self->SUPER::top_targets(@_);
    $top_targets =~ s/all :: pure_all manifypods/all :: pure_all manifypods htmlifypods/;
    $top_targets .= <<'EOF';
htmlifypods : $(TO_INST_PM)
	if [ ! -d blib/html ]; then mkdir blib/html; fi
	perl -MPod::Simple::HTMLBatch -e Pod::Simple::HTMLBatch::go lib blib/html
	-perl -MPod::Simple::HTML -e Pod::Simple::HTML::go bin/youri-check blib/html/youri-check.html
EOF
     return $top_targets;
}

sub install {
    my ($self) = @_;
    my $install = $self->SUPER::install(@_);
    $install =~ s/install :: all pure_install doc_install/install :: all pure_install doc_install config_install completion_install/;
    $install .= <<'EOF';
config_install :
	install -d -m 755 $(DESTDIR)$(SYSCONFDIR)/youri
	install -m 644 etc/check.conf $(DESTDIR)$(SYSCONFDIR)/youri

completion_install :
	install -d -m 755 $(DESTDIR)$(SYSCONFDIR)/bash_completion.d
	install -m 644 etc/bash_completion.d/youri-check $(DESTDIR)$(SYSCONFDIR)/bash_completion.d
EOF
    return $install;
}

sub installbin {
    my ($self) = @_;
    my $installbin = $self->SUPER::installbin(@_);
    $installbin .= <<'EOF';
bin/youri-check : bin/youri-check.in Makefile
	perl -p \
	    -e 's|\@sysconfdir\@|$(SYSCONFDIR)|;' \
	    < $< > $@

EOF
    return $installbin;
}
