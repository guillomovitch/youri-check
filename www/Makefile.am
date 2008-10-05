wwwdir = $(datadir)/youri/www

www_SCRIPTS = report.cgi

CLEANFILES = $(www_SCRIPTS)
EXTRA_DIST = report.cgi.in

report.cgi: report.cgi.in
	perl -pi \
		-e 's|\@sysconfdir\@|$(sysconfdir)|;' \
		-e 's|\@perllibdir\@|$(perllibdir)|;' \
		-e 's|\@templatesdir\@|$(templatesdir)|;' \
		< $< > $@
	chmod +x $@
