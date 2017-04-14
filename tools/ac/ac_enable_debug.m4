# -*- m4 -*-
#
# $Id$
#
# Blame: Jordan Hrycaj <jordan@teddy-net.com>

# ---------------------------------------------------------------------------
# Makefile.am config.h: cong argument
# ---------------------------------------------------------------------------

AC_DEFUN([AC_ENABLE_DEBUG],[
  AC_REQUIRE([AC_BUILDENV_INIT])
  AC_REQUIRE([AC_PROG_GCC_STRICT_ALIASING])
  AC_REQUIRE([AC_PROG_GCC_WEXTRA])
  dnl
  AC_ARG_WITH([valgrind],
    [AC_HELP_STRING([--with-valgrind],
       [use the valgrind client support library])])
  dnl
  AC_ARG_ENABLE([debug],
    [AC_HELP_STRING([--enable-debug],
       [enable source code debug mode])])
  dnl
  AC_ARG_ENABLE([profile],
    [AC_HELP_STRING([--enable-profile],
       [enable GCC source code profiling mode])])
  dnl
  AC_ARG_ENABLE([optimiser],
    [AC_HELP_STRING([--enable-optimiser],
       [turns on the compiler optimiser flags (default with gcc is -O6)])])
  dnl
  mw="Cannot disable debugging while "
  dnl
  dnl valgrind => debug
  if test yes = "$with_valgrind"; then
     if test no = "$enable_debug" ; then
       AC_MSG_ERROR([$m valgrind is activated])
     fi
     enable_debug=yes
  fi
  dnl
  dnl profiler => debug
  if test yes = "$enable_profile"; then
     if test no = "$enable_debug" ; then
       AC_MSG_ERROR([$m profiling is activated])
     fi
     enable_debug=yes
  fi
])


AC_DEFUN([AC_CHECK_DEBUG],[
  AC_REQUIRE([AC_PROG_CC])
  if test yes = "$with_valgrind"; then
     AC_CHECK_HEADERS([valgrind/memcheck.h],,
                      [AC_MSG_ERROR([Missing valgrind headers])])
     AC_DEFINE([WITH_VALGRIND],[1],[enable memory debugging mode])
  fi
  dnl
  AC_INIT_IFGCC([GCC debugging options],
    [GCC_CFLAGS="$GCC_CFLAGS -Wall"
     if test yes = "$enable_profile"; then
       PROFILING_CFLAGS="-pg -fprofile-generate --coverage"
       GCC_CFLAGS="$GCC_CFLAGS $PROFILING_CFLAGS"
       AC_DEFINE([USE_PROFILING],[1],[enable GCC source code profiling mode])
       AC_SUBST([PROFILING_CFLAGS])
     fi
     if test yes = "$enable_debug"; then
       CFLAGS=`echo "$CFLAGS" | sed 's/-O@<:@0-9@:>@*//'`
       GCC_CFLAGS="$GCC_CFLAGS $CFLAGS_GCC_STRICT_ALIASING"
       AC_DEFINE([USE_DEBUG],[1],[enable source code debugging mode])
     fi
     if test yes = "$enable_optimiser"; then
       case $GCC_VERSION in O@<:@04-9@:>@*)x=6;;*)x=3;esac
       GCC_CFLAGS="$GCC_CFLAGS $CFLAGS_GCC_STRICT_ALIASING2 -O$x"
     fi
     case "$GCC_VARIANT:$GCC_VERSION" in *cc*:@<:@123@:>@.*);;
     *) GCC_CFLAGS="$GCC_CFLAGS -Werror $CFLAGS_GCC_WEXTRA"
     esac])
  dnl
  AM_CONDITIONAL([USE_VALGRIND],[test yes = "$with_valgrind"])
  AM_CONDITIONAL([USE_PROFILE], [test yes = "$enable_profile"])
  AM_CONDITIONAL([USE_DEBUG],   [test yes = "$enable_debug"])
  AC_SUBST([GCC_CFLAGS])
])

AC_DEFUN([AC_MSG_DEBUG],[
  dnl
   unset m p
  if test yes = "$with_valgrind"; then
    m="Valgrind"
  fi
  dnl
  if test yes = "$enable_debug"; then
    if test yes = "$enable_profile"; then
       p="/profile"
    fi
    if test -z "$m"; then
      m="Source code debug$p mode"
    else
      m="$m, source code debug$p mode"
    fi
  fi
  dnl
  if test yes = "$enable_optimiser"; then
    if test -z "$m"; then
      m="Compiler optimises"
    else
      m="$m, compiler optimises"
    fi
  fi
  if test -n "$m"; then
     AC_MSG_NOTICE([$m])
  fi
])

# ---------------------------------------------------------------------------
# End
# ---------------------------------------------------------------------------
