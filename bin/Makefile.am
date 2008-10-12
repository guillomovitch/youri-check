bin_SCRIPTS = youri-check
man1_MANS   = youri-check.1

CLEANFILES = $(bin_SCRIPTS) $(man1_MANS)
EXTRA_DIST = youri-check.in

youri-check: youri-check.in
	perl -pi \
		-e 's|\@sysconfdir\@|$(sysconfdir)|;' \
		-e 's|\@perllibdir\@|$(perllibdir)|;' \
		< $< > $@
	chmod +x $@

youri-check.1: youri-check
	pod2man $< $@

