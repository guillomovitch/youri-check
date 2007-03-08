bin_SCRIPTS = youri-check
man1_MANS   = youri-check.1

CLEANFILES = youri-check \
	     youri-check.1
EXTRA_DIST = youri-check.in

youri-check: youri-check.in
	perl -pi \
		-e 's|\@sysconfdir\@|$(sysconfdir)|;' \
		-e 's|\@perllibdir\@|$(perllibdir)|;' \
		< $< > $@

youri-check.1: youri-check
	pod2man $< $@

