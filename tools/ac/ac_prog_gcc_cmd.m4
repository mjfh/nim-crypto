# -*- m4 -*-
#
# $Id$
#
# Blame: Jordan Hrycaj <jordan@teddy-net.com>
#
# inspired by http://autoconf-archive.cryp.to/ax_gcc_warn_unused_result.html
#

# ---------------------------------------------------------------------------
# config.h & macros: gcc/clang commandline options
# ---------------------------------------------------------------------------

dnl Syntax: _AC_PROG_GCC_COMP_OPTION(cmdline-option,
dnl                                  [varname],
dnl                                  [action-if-present],
dnl                                  [action-otherwise])
AC_DEFUN([_AC_PROG_GCC_COMP_OPTION],[
  AC_INIT_IFGCC([GCC $1],

    [save_CFLAGS="$CFLAGS"
     CFLAGS="$CFLAGS $1"
     AC_MSG_CHECKING([for GCC supporting $1])
     dnl
     AC_COMPILE_IFELSE([AC_LANG_SOURCE([
       [int f() { exit (0); }]])],

       [m4_ifvaln([$2],[$2="$1"])dnl
        m4_ifvaln([$3],[$3])dnl
        AC_MSG_RESULT([yes])],

       [m4_ifvaln([$2],[$2=])dnl
        m4_ifvaln([$4],[$4])dnl
        AC_MSG_RESULT([no])])
     dnl
     CFLAGS="$save_CFLAGS"])
])

# ---------------------------------------------------------------------------
# config.h: HAVE_GCC_FWRAPV, Makefile.am: USE_GCC_FWRAPV
# ---------------------------------------------------------------------------

AC_DEFUN([AC_PROG_GCC_FWRAPV],[
  _AC_PROG_GCC_COMP_OPTION([-fwrapv],[USE_GCC_FWRAPV],
     [AC_DEFINE([HAVE_GCC_FWRAPV],[1],[if gcc supports option -fwrapv])])
  AC_SUBST([USE_GCC_FWRAPV])
])

# ---------------------------------------------------------------------------
# internal: CFLAGS_GCC_##: WEXTRA; WERROR_##: FORMAT IMPLICIT ATTRIBUTES
# ---------------------------------------------------------------------------

AC_DEFUN([AC_PROG_GCC_M32],[
 _AC_PROG_GCC_COMP_OPTION([-m32],[CFLAGS_GCC_M32])
])

AC_DEFUN([AC_PROG_GCC_M64],[
 _AC_PROG_GCC_COMP_OPTION([-m64],[CFLAGS_GCC_M64])
])

AC_DEFUN([AC_PROG_GCC_WEXTRA],[
 _AC_PROG_GCC_COMP_OPTION([-Wextra],[CFLAGS_GCC_WEXTRA])
])

AC_DEFUN([AC_PROG_GCC_WERROR_FORMAT],[
 _AC_PROG_GCC_COMP_OPTION([-Werror=format],
                          [CFLAGS_GCC_WERROR_FORMAT])
])

AC_DEFUN([AC_PROG_GCC_WERROR_IMPLICIT],[
 _AC_PROG_GCC_COMP_OPTION([-Werror=implicit],
                          [CFLAGS_GCC_WERROR_IMPLICIT])
])

AC_DEFUN([AC_PROG_GCC_WERROR_ATTRIBUTES],[
 _AC_PROG_GCC_COMP_OPTION([-Werror=attributes],
                          [CFLAGS_GCC_WERROR_ATTRIBUTES])
])

# ---------------------------------------------------------------------------
# internal: CFLAGS_GCC_STRICT_ALIASING
# ---------------------------------------------------------------------------

AC_DEFUN([AC_PROG_GCC_STRICT_ALIASING2],[
 _AC_PROG_GCC_COMP_OPTION([-fstrict-aliasing=2],
                          [CFLAGS_GCC_STRICT_ALIASING])
])

AC_DEFUN([AC_PROG_GCC_STRICT_ALIASING],[
 _AC_PROG_GCC_COMP_OPTION([-fstrict-aliasing],
                          [CFLAGS_GCC_STRICT_ALIASING])
])

# ---------------------------------------------------------------------------
# End
# ---------------------------------------------------------------------------
