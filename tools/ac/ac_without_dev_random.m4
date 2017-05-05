# -*- m4 -*-
#
# $Id$
#
# Blame: Jordan Hrycaj <jordan@teddy-net.com>

# ---------------------------------------------------------------------------
# config.h: check whether we have /dev/random or something similar
# ---------------------------------------------------------------------------

AC_DEFUN([AC_WITHOUT_DEV_RANDOM],[
  AC_ARG_WITH([dev_random],
              [AC_HELP_STRING([--without-dev-random],
              [explicitely disable the use of /dev/random
               (if present, at all))])],
              try_dev_random=$withval,try_dev_random=yes)
])

AC_DEFUN([AC_CHECK_DEV_RANDOM],[
  have_dev_random=no

  AC_INIT_IFMINGW([random devices],,[
    DEV_URANDOM="/dev/urandom"
    DEV_RANDOM="/dev/random"

    case "${target}" in *-openbsd*)
      DEV_RANDOM="/dev/srandom"
    esac

    AC_MSG_CHECKING([for devices $DEV_RANDOM and $DEV_URANDOM])

    if test "$try_dev_random" = yes; then
      if test -c "$DEV_RANDOM" -a -c "$DEV_URANDOM"; then
	have_dev_random=yes;
      else
	have_dev_random=no;
      fi
      AC_MSG_RESULT([$have_dev_random])

      if test "$have_dev_random" = yes; then
	AC_DEFINE_UNQUOTED([DEV_RANDOM],
	                   ["$DEV_RANDOM"],
			   [random device path])
	AC_DEFINE_UNQUOTED([DEV_URANDOM],
                           ["$DEV_URANDOM"],
			   [urandom device path])
	AC_DEFINE([HAVE_DEV_RANDOM],[1],[enable usage of random devices])
      fi
    else
      AC_MSG_RESULT([disabled])
    fi
])])

AC_DEFUN([AC_MSG_DEV_RANDOM],[
  if test  "x$have_dev_random" = xyes; then
    AC_MSG_NOTICE([Random devices are $DEV_RANDOM and $DEV_URANDOM])
  else
    if test x${try_dev_random} = xno; then
      msg="(disabled)";
    else
      msg="(missing)";
    fi
    AC_MSG_NOTICE([No random device available $msg])
  fi
])

# ---------------------------------------------------------------------------
# End
# ---------------------------------------------------------------------------
