yourisysconfdir = $(sysconfdir)/youri
completiondir = $(sysconfdir)/bash_completion.d

dist_noinst_DATA  = check.conf
dist_completion_SCRIPTS = youri-check

# preserve existing configuration files
install-data-hook:
	if [ -f $(DESTDIR)$(yourisysconfdir)/check.conf ]; then \
		install -m 644 check.conf \
			$(DESTDIR)$(yourisysconfdir)/check.conf.new; \
	else \
		install -m 644 check.conf \
			$(DESTDIR)$(yourisysconfdir)/check.conf; \
	fi
