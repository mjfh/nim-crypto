# -*- m4 -*-
#
# $Id$
#
# Blame: Jordan Hrycaj <jordan@teddy-net.com>
#
# Source:
#   /usr/share/autoconf-archive/html/ac_func_vsnprintf.html
#
# Licence
#   Copyright 2008 Gaute Strokkenes, GNU General Public License
#
dnl syntax: _AC_FUNCS_VSNPRINTF_RUN <function>
dnl                                 [action-if-available]
dnl                                 [action-if-missing]
dnl                                 [action-if-xcompiling]
AC_DEFUN([_AC_FUNCS_VSNPRINTF_RUN],[
  AC_MSG_CHECKING([for $1() fully Posix/C99])
  AC_RUN_IFELSE([AC_LANG_PROGRAM([
    AC_INCLUDES_DEFAULT
    AC_INCLUDES_WINDOWS
    [
#        ifdef HAVE_STDARG_H
#        include <stdarg.h>
#        endif

         int t (char *s, ...) {
           char buf [32];
           va_list args;
           int r;

           buf [5] = 88; /* ascii X */
           va_start (args, s);
           r = $1 (buf, 5, s, args);
           va_end (args);

           /* -1 is pre-C99, 7 is C99. */
           if (r == 7) {
	     buf [4] = 0;
	     if (strcmp (buf, "1234") == 0 && buf [5] == 88)
               return 0 ;
           }
           return 1;
         }
    ]],[[
      exit (t ("1234567"));
    ]])],[AC_MSG_RESULT([yes]); $2],
         [AC_MSG_RESULT([no]);  $3],
         [$4])
])

# ---------------------------------------------------------------------------
# config.h: check whether vsnprintf() works as expected
# ---------------------------------------------------------------------------

AC_DEFUN([AC_FUNC_VSNPRINTF],[
  AH_VERBATIM([HAVE__SNPRINTF],
    [/* Defined on Visual Studio etc. */
#undef HAVE__SNPRINTF])
  dnl
  AC_CHECK_FUNCS([snprintf])
  AC_REQUIRE([AC_CHECK_MSWIN_STDIO])
  dnl
  AC_LANG_PUSH([C])
  _AC_FUNCS_VSNPRINTF_RUN([vsnprintf],
    [ac_func_vsnprintf_c99=yes],
    [ac_func_vsnprintf_c99=no],
    [AC_INIT_IFMINGW([MinGW vsnprintf support],
      [case $have_mswin_stdio in
       yes*) ac_func_vsnprintf_c99=no ;;
       *)    ac_func_vsnprintf_c99=yes
       esac
       AC_MSG_RESULT([$ac_func_vsnprintf_c99 (guessed)])],
      [AC_MSG_ERROR([Cross compiling: vsnprintf support unknown!])])
  AC_LANG_POP([C])])
  dnl
  if test $ac_func_vsnprintf_c99 = yes; then
    AC_DEFINE([HAVE_VSNPRINTF_C99],[1],
      [Define if you have a C99/Posix version of vsnprintf().])
  fi
])

# ---------------------------------------------------------------------------
# End
# ---------------------------------------------------------------------------
