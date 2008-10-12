nobase_perllib_DATA = Youri/Check/Database.pm \
		      Youri/Check/Schema.pm \
		      Youri/Check/Schema/Age.pm \
		      Youri/Check/Schema/Maintainer.pm \
		      Youri/Check/Schema/Package.pm \
		      Youri/Check/Schema/PackageFile.pm \
		      Youri/Check/Schema/Section.pm \
		      Youri/Check/Schema/TestRun.pm \
		      Youri/Check/Schema/Updates.pm \
		      Youri/Check/Plugin.pm \
		      Youri/Check/Plugin/Report.pm \
		      Youri/Check/Plugin/Test.pm \
		      Youri/Check/Plugin/Test/Build/Source/LBD.pm \
		      Youri/Check/Plugin/Test/Build/Source/Iurt.pm \
		      Youri/Check/Plugin/Test/Build/Source.pm \
		      Youri/Check/Plugin/Test/Conflicts.pm \
		      Youri/Check/Plugin/Test/Rpmlint.pm \
		      Youri/Check/Plugin/Test/Updates.pm \
		      Youri/Check/Plugin/Test/Dependencies.pm \
		      Youri/Check/Plugin/Test/MandrivaConflicts.pm \
		      Youri/Check/Plugin/Test/Missing.pm \
		      Youri/Check/Plugin/Test/Unmaintained.pm \
		      Youri/Check/Plugin/Test/Updates/Source/GNOME.pm \
		      Youri/Check/Plugin/Test/Updates/Source/Gentoo.pm \
		      Youri/Check/Plugin/Test/Updates/Source/Freshmeat.pm \
		      Youri/Check/Plugin/Test/Updates/Source/NetBSD.pm \
		      Youri/Check/Plugin/Test/Updates/Source/Fedora.pm \
		      Youri/Check/Plugin/Test/Updates/Source/CPAN.pm \
		      Youri/Check/Plugin/Test/Updates/Source/Debian.pm \
		      Youri/Check/Plugin/Test/Updates/Source/RAA.pm \
		      Youri/Check/Plugin/Test/Updates/Source/Sourceforge.pm \
		      Youri/Check/Plugin/Test/Updates/Source.pm \
		      Youri/Check/Plugin/Test/Age.pm \
		      Youri/Check/Plugin/Test/Rpmcheck.pm \
		      Youri/Check/Plugin/Test/Build.pm \
		      Youri/Check/Plugin/Test/Signature.pm \
		      Youri/Check/Plugin/Report/Mail.pm \
		      Youri/Check/Plugin/Report/Mail/Format.pm \
		      Youri/Check/Plugin/Report/Mail/Format/HTML.pm \
		      Youri/Check/Plugin/Report/Mail/Format/Text.pm \
		      Youri/Check/Maintainer/Preferences/File.pm \
		      Youri/Check/Maintainer/Resolver/Bugzilla.pm \
		      Youri/Check/Maintainer/Resolver/CGI.pm \
		      Youri/Check/Maintainer/Preferences.pm \
		      Youri/Check/Maintainer/Resolver.pm \
		      Youri/Check/Descriptor/Row.pm \
		      Youri/Check/Descriptor/Cell.pm

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
