# -*- m4 -*-
#
# $Id$
#
# Blame: Jordan Hrycaj <jordan@teddy-net.com>

# ---------------------------------------------------------------------------
# enable/disable support for WINE command
# ---------------------------------------------------------------------------

AC_DEFUN([AC_WITH_WINE],[
  AC_ARG_WITH([wine],
	      [AC_HELP_STRING([--with-wine@<:@=DIR@:>@],
                              [location of installed WINE command for X-testing,
	                       "auto" (is default), or "no" to disable])])
  case "${with_wine:-auto}" in
  auto) use_wine=try ;;
  yes)  use_wine=yes; WINE_EXE= ;;
  /*)   use_wine=yes; WINE_EXE="${with_wine}" ;;
  no)   use_wine=no ;;
  *)    msg="Need absoute path for WINE"
        AC_MSG_ERROR([$msg (got only "$with_wine")])
  esac
])

# ---------------------------------------------------------------------------
# check for WINE tool
# ---------------------------------------------------------------------------

AC_DEFUN([AC_CHECK_WINE],[
  dnl find WINE unless disabled
  unset CMDPATH_WINE
  if test yes = "$use_wine"; then
    if test -z $WINE_EXE ; then
      AC_CHECK_CMDPATH([wine],[$PATH])
    elif test -x "$WINE_EXE" ; then
      CMDPATH_WINE="WINE_EXE"
    fi
    dnl verify that we got something
    if test -z "$CMDPATH_WINE"; then
      AC_MSG_ERROR([Command 'wine' is not available although required])
    fi
  elif test no != "$use_wine"; then
    AC_CHECK_CMDPATH([wine],[$PATH])
  fi
  dnl
  AM_CONDITIONAL([USE_WINE],[test -n "$CMDPATH_WINE"])dnl
  AC_SUBST(CMDPATH_WINE)dnl
])

AC_DEFUN([AC_MSG_WINE],[
  case "$CMDPATH_WINE:$use_wine" in
  ?*:*) AC_MSG_NOTICE([Using WINE command path '$CMDPATH_WINE']);;
  *:no) ;;
  *)    AC_MSG_NOTICE([WINE command path is not available])
  esac
])

# ---------------------------------------------------------------------------
# End
# ---------------------------------------------------------------------------
