# -*- m4 -*-
#
# $Id$
#
# Blame: Jordan Hrycaj <jordan@teddy-net.com>

# ---------------------------------------------------------------------------
# NIM compile time support
# ---------------------------------------------------------------------------

AC_DEFUN([AC_CONFIG_4BUILD],[
  AC_REQUIRE([AC_BUILDENV_INIT])dnl
  dnl
  AC_INIT_IFXCOMPILE([NIM4BUILD],
    [cmd="\$(NIM) cc --skipParentCfg"
     cmd="$cmd -p:\$(SRCLIB_DIR)"
     cmd="$cmd -p:\$(SRCLIB_DIR)/crypto/src/lib"
     cmd="$cmd -d:nim4Build"],
    [cmd="\$(SHELL) ./nim.sh"])
  NIM4BUILD="$cmd"
  AC_SUBST([NIM4BUILD])
  dnl
  AC_INIT_IFXCOMPILE([EXEEXT4BUILD],
    [if test -x "$SHELL"; then
       var=`expr "$SHELL" : '.*\(\...*\)'`
     elif test -x "$SHELL.exe"; then
       var=.exe
     else
       cmd=`ls "$SHELL.exe" 2>/dev/null|sed q`
       var=`expr "$cmd" : '.*\(\...*\)' \| ""`
     fi],
    [var="\$(EXEEXT)"])
  EXEEXT4BUILD="$var"
  AC_SUBST([EXEEXT4BUILD])
])

# ---------------------------------------------------------------------------
# End
# ---------------------------------------------------------------------------
