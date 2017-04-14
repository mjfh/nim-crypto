# -*- m4 -*-
#
# $Id$
#
# Blame: Jordan Hrycaj <jordan@teddy-net.com>


# ---------------------------------------------------------------------------
# Makefile.am: check package for unit tests
# ---------------------------------------------------------------------------

AC_DEFUN([AC_DISABLE_UNIT_TESTS],[
  disable_unit_tests=no
  AC_ARG_ENABLE([unit-tests],
    [AC_HELP_STRING([--disable-unit-tests],
       [disable unit tests])],
    [if test "x$enableval" = xno; then
       disable_unit_tests=yes
     fi])
])

AC_DEFUN([AC_CHECK_UNIT_TESTS],[
  have_unit_tests=no
  AC_INIT_IFXCOMPILE([Unit tests],,[
    if test "x${disable_unit_tests}" = xyes ; then
      AC_MSG_NOTICE([Unit tests are disabled])
    m4_ifdef([PKG_CHECK_MODULES],[else
      AC_CHECK_HEADER([check.h],
        [PKG_CHECK_MODULES([CHECK],[check >= 0.9.4],
          [have_unit_tests=yes
           AC_DEFINE([HAVE_CHECK_H],[1],
             [Define if you have the "check" unit tests interface])
           AC_DEFINE([HAVE_UNIT_TESTS],[1],
             [Define to enable unit tests])
	   CHECK_CFLAGS=`pkg-config --cflags --libs check`
	   CHECK_LIBS=`pkg-config --libs --libs check`
	   AC_SUBST([CHECK_CFLAGS])
	   AC_SUBST([CHECK_LIBS])])])],
      [m4_errprintn([Warning(CHECK_UNIT_TESTS): pkg-config not installed])])
    fi])
    dnl
    AM_CONDITIONAL([USE_UNIT_TESTS],[test "x$have_unit_tests" = xyes])
])

AC_DEFUN([AC_MSG_UNIT_TESTS],[
  msg="Unit tests (check)"
  if test "x$have_unit_tests" = xyes ; then
     AC_MSG_NOTICE([$msg will be available])
  elif test "x$disable_unit_tests" = xyes ; then
     AC_MSG_NOTICE([$msg have been deconfigured])
  else
     AC_MSG_NOTICE([$msg will NOT be available])
  fi
])

# ---------------------------------------------------------------------------
# End
# ---------------------------------------------------------------------------
