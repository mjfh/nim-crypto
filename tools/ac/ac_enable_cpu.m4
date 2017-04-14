# -*- m4 -*-
#
# $Id$
#
# Blame: Jordan Hrycaj <jordan@teddy-net.com>

# ---------------------------------------------------------------------------
# Makefile.am: enable cpu 32/64 mode
# ---------------------------------------------------------------------------

AC_DEFUN([AC_ENABLE_CPU],[
  AC_ARG_ENABLE([cpu],
    [AC_HELP_STRING([--enable-cpu=32/64],[force cpu type])],
    [ case "$enableval" in
     '')       force_cpu32=no  ; force_cpu64=no  ;;
     32|i386)  force_cpu32=yes ; force_cpu64=no  ;;
     64|amd64) force_cpu32=no  ; force_cpu64=yes ;;
      *)       AC_MSG_ERROR([Unkown CPU type "$enableval"])
     esac])
])

AC_DEFUN([AC_CHECK_CPU],[
  AC_REQUIRE([AC_PROG_GCC_M32])
  AC_REQUIRE([AC_PROG_GCC_M64])
  AC_REQUIRE([AC_BUILDENV_INIT])

  if test "$force_cpu32" = yes -a -z "$CFLAGS_GCC_M32" ; then
    AC_MSG_ERROR([GCC does not support m32 mode])
  else
    CFLAGS_CC_M32="$CFLAGS_GCC_M32"
  fi
  if test "$force_cpu64" = yes -a -z "$CFLAGS_GCC_M64" ; then
    AC_MSG_ERROR([GCC does not support m32 mode])
  else
    CFLAGS_CC_M64="$CFLAGS_GCC_M64"
  fi

  AC_SUBST([CFLAGS_CC_M32])
  AC_SUBST([CFLAGS_CC_M64])
  AM_CONDITIONAL([USE_CPU32], [test "$force_cpu32" = yes])dnl
  AM_CONDITIONAL([USE_CPU64], [test "$force_cpu64" = yes])dnl
])

AC_DEFUN([AC_MSG_CPU],[
  msg="Build system: $BUILD_CONFIG_ID, forcing"
  if test "$force_cpu32" = yes ; then
    AC_MSG_NOTICE([$msg 32bit cpu target])
  elif test "$force_cpu64" = yes ; then
    AC_MSG_NOTICE([$msg 64bit cpu target])
  else
    AC_MSG_NOTICE([Build/target system: $BUILD_CONFIG_ID])
  fi
])

# ---------------------------------------------------------------------------
# End
# ---------------------------------------------------------------------------
