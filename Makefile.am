SVNPATH = svn+ssh://youri.zarb.org/home/projects/youri/svn/soft/check

SUBDIRS = bin lib etc t

svntag:
	svn copy -m 'new release $(VERSION)'\
		$(SVNPATH)/trunk \
		$(SVNPATH)/tags/release-$(VERSION)
