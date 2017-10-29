AC_PREREQ(2.59)
AC_INIT([youri-check], [0.10.4])
AM_INIT_AUTOMAKE([-Wall -Werror foreign])

AC_PATH_PROG([PERL],[perl])
if test -z $PERL; then
    AC_MSG_ERROR([perl not found, aborting])
fi

AC_PATH_PROG([POD2MAN],[pod2man])
if test -z $POD2MAN; then
    AC_MSG_ERROR([pod2man not found, aborting])
fi

perllibdir=$datadir/youri/lib
AC_SUBST(perllibdir)

AC_CONFIG_FILES([Makefile bin/Makefile lib/Makefile etc/Makefile t/Makefile])
AC_OUTPUT
