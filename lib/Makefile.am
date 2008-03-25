nobase_perllib_DATA = Youri/Check/Maintainer/Preferences/File.pm \
		      Youri/Check/Maintainer/Resolver/Bugzilla.pm \
		      Youri/Check/Maintainer/Resolver/CGI.pm \
		      Youri/Check/Maintainer/Preferences.pm \
		      Youri/Check/Maintainer/Resolver.pm \
		      Youri/Check/Resultset/Iterator.pm \
		      Youri/Check/Resultset/DBI.pm

EXTRA_DIST = $(nobase_perllib_DATA)

install-data-hook:
	$(INSTALL) -d -m 755 $(DESTDIR)$(mandir)/man3
	for file in $(nobase_perllib_DATA); do \
	    page=`echo $$file | sed -e 's/\//::/g' -e 's/\.pm$$/.3pm/'`; \
	    $(POD2MAN) --section=3 $(srcdir)/$$file \
	        $(DESTDIR)$(mandir)/man3/$$page; \
	done

uninstall-hook:
	for file in $(nobase_perllib_DATA); do \
	    page=`echo $$file | sed -e 's/\//::/g' -e 's/\.pm$$/.3pm/'`; \
	    rm -f $(DESTDIR)$(mandir)/man3/$$page; \
	done
