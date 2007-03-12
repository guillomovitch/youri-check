nobase_perllib_DATA = Youri/Check/Test/Build/Source/LBD.pm \
		      Youri/Check/Test/Build/Source/Iurt.pm \
		      Youri/Check/Test/Build/Source.pm \
		      Youri/Check/Test/Conflicts.pm \
		      Youri/Check/Test/Rpmlint.pm \
		      Youri/Check/Test/Updates.pm \
		      Youri/Check/Test/Dependencies.pm \
		      Youri/Check/Test/MandrivaConflicts.pm \
		      Youri/Check/Test/Missing.pm \
		      Youri/Check/Test/Orphans.pm \
		      Youri/Check/Test/Updates/Source/GNOME.pm \
		      Youri/Check/Test/Updates/Source/Gentoo.pm \
		      Youri/Check/Test/Updates/Source/Freshmeat.pm \
		      Youri/Check/Test/Updates/Source/NetBSD.pm \
		      Youri/Check/Test/Updates/Source/Fedora.pm \
		      Youri/Check/Test/Updates/Source/CPAN.pm \
		      Youri/Check/Test/Updates/Source/Debian.pm \
		      Youri/Check/Test/Updates/Source/RAA.pm \
		      Youri/Check/Test/Updates/Source/Sourceforge.pm \
		      Youri/Check/Test/Updates/Source.pm \
		      Youri/Check/Test/Age.pm \
		      Youri/Check/Test/Rpmcheck.pm \
		      Youri/Check/Test/Build.pm \
		      Youri/Check/Test/Signature.pm \
		      Youri/Check/Resultset.pm \
		      Youri/Check/Report.pm \
		      Youri/Check/Test.pm \
		      Youri/Check/Plugin.pm \
		      Youri/Check/Maintainer/Preferences/File.pm \
		      Youri/Check/Maintainer/Resolver/Bugzilla.pm \
		      Youri/Check/Maintainer/Resolver/CGI.pm \
		      Youri/Check/Maintainer/Preferences.pm \
		      Youri/Check/Maintainer/Resolver.pm \
		      Youri/Check/Resultset/Iterator.pm \
		      Youri/Check/Resultset/DBI.pm \
		      Youri/Check/Report/File.pm \
		      Youri/Check/Report/Mail.pm \
		      Youri/Check/Report/Format.pm \
		      Youri/Check/Report/Format/HTML.pm \
		      Youri/Check/Report/Format/Text.pm \
		      Youri/Check/Report/Format/RSS.pm \
		      Youri/Check/Descriptor/Row.pm \
		      Youri/Check/Descriptor/Cell.pm

noinst_man3_MANS = Youri/Check/Test/Build/Source/LBD.3pm \
	    Youri/Check/Test/Build/Source/Iurt.3pm \
	    Youri/Check/Test/Build/Source.3pm \
	    Youri/Check/Test/Conflicts.3pm \
	    Youri/Check/Test/Rpmlint.3pm \
	    Youri/Check/Test/Updates.3pm \
	    Youri/Check/Test/Dependencies.3pm \
	    Youri/Check/Test/MandrivaConflicts.3pm \
	    Youri/Check/Test/Missing.3pm \
	    Youri/Check/Test/Orphans.3pm \
	    Youri/Check/Test/Updates/Source/GNOME.3pm \
	    Youri/Check/Test/Updates/Source/Gentoo.3pm \
	    Youri/Check/Test/Updates/Source/Freshmeat.3pm \
	    Youri/Check/Test/Updates/Source/NetBSD.3pm \
	    Youri/Check/Test/Updates/Source/Fedora.3pm \
	    Youri/Check/Test/Updates/Source/CPAN.3pm \
	    Youri/Check/Test/Updates/Source/Debian.3pm \
	    Youri/Check/Test/Updates/Source/RAA.3pm \
	    Youri/Check/Test/Updates/Source/Sourceforge.3pm \
	    Youri/Check/Test/Updates/Source.3pm \
 	    Youri/Check/Test/Age.3pm \
 	    Youri/Check/Test/Rpmcheck.3pm \
	    Youri/Check/Test/Build.3pm \
	    Youri/Check/Test/Signature.3pm \
	    Youri/Check/Resultset.3pm \
	    Youri/Check/Report.3pm \
	    Youri/Check/Test.3pm \
	    Youri/Check/Plugin.3pm \
	    Youri/Check/Maintainer/Preferences/File.3pm \
	    Youri/Check/Maintainer/Resolver/Bugzilla.3pm \
	    Youri/Check/Maintainer/Resolver/CGI.3pm \
	    Youri/Check/Maintainer/Preferences.3pm \
	    Youri/Check/Maintainer/Resolver.3pm \
	    Youri/Check/Resultset/Iterator.3pm \
	    Youri/Check/Resultset/DBI.3pm \
	    Youri/Check/Report/File.3pm \
	    Youri/Check/Report/Mail.3pm \
	    Youri/Check/Report/Format.3pm \
	    Youri/Check/Report/Format/HTML.3pm \
	    Youri/Check/Report/Format/Text.3pm \
	    Youri/Check/Report/Format/RSS.3pm \
	    Youri/Check/Descriptor/Row.3pm \
	    Youri/Check/Descriptor/Cell.3pm

CLEANFILES = $(noinst_man3_MANS)

EXTRA_DIST = $(nobase_perllib_DATA)

.pm.3pm:
	$(POD2MAN) $< > $@

install-hook:
	for page in $(noinst_man3_MANS); do \
	    $(INSTALL) -m 644 $$page \
	        $(DESTDIR)$(mandir)/man3/`echo $$page | sed -e 's/\//::/g'`; \
	done
