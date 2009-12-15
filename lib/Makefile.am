nobase_perllib_DATA = Youri/Check/Database.pm \
		      Youri/Check/Schema.pm \
		      Youri/Check/Schema/Age.pm \
		      Youri/Check/Schema/Maintainer.pm \
		      Youri/Check/Schema/Package.pm \
		      Youri/Check/Schema/RPM.pm \
		      Youri/Check/Schema/Section.pm \
		      Youri/Check/Schema/TestRun.pm \
		      Youri/Check/Schema/Updates.pm \
		      Youri/Check/Test.pm \
		      Youri/Check/Test/Build/Source/LBD.pm \
		      Youri/Check/Test/Build/Source/Iurt.pm \
		      Youri/Check/Test/Build/Source.pm \
		      Youri/Check/Test/Conflicts.pm \
		      Youri/Check/Test/Rpmlint.pm \
		      Youri/Check/Test/Updates.pm \
		      Youri/Check/Test/Dependencies.pm \
		      Youri/Check/Test/MandrivaConflicts.pm \
		      Youri/Check/Test/Missing.pm \
		      Youri/Check/Test/Unmaintained.pm \
		      Youri/Check/Test/Updates/Source.pm \
		      Youri/Check/Test/Updates/Source/Apache.pm \
		      Youri/Check/Test/Updates/Source/CPAN.pm \
		      Youri/Check/Test/Updates/Source/Debian.pm \
		      Youri/Check/Test/Updates/Source/Fedora.pm \
		      Youri/Check/Test/Updates/Source/Freshmeat.pm \
		      Youri/Check/Test/Updates/Source/GNOME.pm \
		      Youri/Check/Test/Updates/Source/Gentoo.pm \
		      Youri/Check/Test/Updates/Source/JPackage.pm \
		      Youri/Check/Test/Updates/Source/NetBSD.pm \
		      Youri/Check/Test/Updates/Source/PEAR.pm \
		      Youri/Check/Test/Updates/Source/RAA.pm \
		      Youri/Check/Test/Updates/Source/Sourceforge.pm \
		      Youri/Check/Test/Age.pm \
		      Youri/Check/Test/Rpmcheck.pm \
		      Youri/Check/Test/Build.pm \
		      Youri/Check/Test/Signature.pm \
		      Youri/Check/Maintainer/Preferences/File.pm \
		      Youri/Check/Maintainer/Resolver/Bugzilla.pm \
		      Youri/Check/Maintainer/Resolver/CGI.pm \
		      Youri/Check/Maintainer/Preferences.pm \
		      Youri/Check/Maintainer/Resolver.pm \
		      Youri/Check/WebRetriever.pm

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
