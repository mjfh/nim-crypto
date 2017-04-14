# -*- m4 -*-
#
# $Id$
#
# Blame: Jordan Hrycaj <jordan@teddy-net.com>

# ---------------------------------------------------------------------------
# config.h: check for standard posix headers
# ---------------------------------------------------------------------------

AC_DEFUN([AC_HEADERS_POSIX],[
  AC_HEADER_STDC
  AC_HEADER_ASSERT
  AC_HEADER_STDBOOL
  AC_HEADER_SYS_WAIT
  AC_HEADER_TIME
  AC_HEADER_STAT
  AC_HEADER_DIRENT
dnl
  AC_CHECK_HEADERS([arpa/inet.h assert.h ctype.h errno.h fcntl.h grp.h])
  AC_CHECK_HEADERS([libgen.h limits.h math.h mntent.h])
  AC_CHECK_HEADERS([netdb.h netinet/in.h])
  AC_CHECK_HEADERS([search.h setjmp.h signal.h])
  AC_CHECK_HEADERS([stdarg.h stddef.h stdio.h syslog.h])
  AC_CHECK_HEADERS([sys/ioctl.h sys/statvfs.h sys/resource.h sys/un.h])
])

# ---------------------------------------------------------------------------
# End
# ---------------------------------------------------------------------------
