# -*- m4 -*-
#
# $Id$
#
# Blame: Jordan Hrycaj <jordan@teddy-net.com>

# ---------------------------------------------------------------------------
# Force/check for OS installation of NIM
# ---------------------------------------------------------------------------

# NIM/GREP - local installation => NIM, NIMLIB
AC_DEFUN([_AC_CHECK_LOCAL_NIM],[
  if test -z "$NIM" -o -z "$NIMLIB"; then
    AC_MSG_CHECKING([for local NIM library installation])
    p=`pwd`/tools/import/nim
    if test -x $p/bin/nim$NIMEXE    -a \
            -x $p/bin/nimble$NIMEXE -a \
	    -s $p/lib/nimbase.h; then
      NIM=$p/bin/nim$NIMEXE
      NIMBLE="env PATH=$p/bin:$PATH $p/bin/nimble"
      NIMLIB=$p/lib
      use_local_nim=yes
    else
      AC_MSG_RESULT([no])
      use_local_nim=no
    fi
  else
    use_local_nim=ignored
  fi
])

# NIM - OS installation => NIM, NIMLIB, NIMBLE
AC_DEFUN([_AC_CHECK_OS_NIM],[

  dnl NIM
  if test -z "$NIM"; then
    AC_CHECK_PROG([nim],[nim],[yes],[no])
    if test "$nim" = yes; then
      NIM=nim$NIMEXE
    fi
  fi

  dnl NIMLIB
  if test -z "$NIMLIB"; then
    AC_MSG_CHECKING([for NIM library with "nimbase.h"])
    NIMLIB=`$NIM dump 2>&1|grep '@<:@/\\\\@:>@lib$'|sort|sed q`
    dnl Check whether Windows/MinGW mapping is needed
    case "$NIMLIB" in @<:@A-Za-z@:>@:\\*)
      NIMLIB=`echo $NIMLIB|sed -e 's!\\\\!/!g' -e 's/^.://'`
    esac
    if test -n "$NIMLIB" -a -s "$NIMLIB/nimbase.h"; then
      AC_MSG_RESULT([$NIMLIB])
    else
      AC_MSG_RESULT([no])
    fi
  fi

  dnl NIMBLE
  if test -z "$NIMBLE"; then
    AC_CHECK_PROG([nimble],[nimble],[yes],[no])
    if test "$nimble" = yes; then
      NIMBLE=nimble$NIMEXE
    else
      # Try nimlib bin
      d=`dirname "$NIMLIB"`/bin
      AC_CHECK_PROG([nimble2],[nimble],[yes],[no],[$d])
      if test "$nimble2" = yes; then
         NIMBLE="env PATH=$d:$PATH $d/nimble$NIMEXE"
      fi
    fi
  fi

  AC_SUBST([NIM])
  AC_SUBST([NIMLIB])
  AC_SUBST([NIMBLE])
  AC_SUBST([NIM2C])
])

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

AC_DEFUN([AC_WITHOUT_LOCAL_NIM],[
  AC_ARG_WITH([local-nim],
    [AC_HELP_STRING([--without-local-nim],
                    [prefer NIM package from operating system])],
    [case "$withval" in
     yes|no) prefer_local_nim=$withval ;;
     *)      msg="Unsupported option argument"
             AC_MSG_NOTICE([$msg "--without-local-nim=$withval"])
     esac],
    [prefer_local_nim=yes])
])

AC_DEFUN([AC_CHECK_LOCAL_NIM],[
  unset NIM NIMLIB NIMEXE

  case "$cross_compiling:$ac_cv_exeext" in
  :.*|no:.*) NIMEXE="$ac_cv_exeext" ;;
  esac

  if test yes = "$prefer_local_nim" ; then
    _AC_CHECK_LOCAL_NIM
    _AC_CHECK_OS_NIM
  else
    _AC_CHECK_OS_NIM
    _AC_CHECK_LOCAL_NIM
  fi

  msg="and set your PATH variable accordingly (or try ./Build nim-lang)!"
  if test -z "$NIM"; then
     AC_MSG_ERROR([Please install NIM $msg])
  fi
  if test -z "$NIMLIB"; then
     AC_MSG_ERROR([Cannot find NIM library])
  fi

  dnl NIM2C
  NIM2C="$NIM cc -c --noMain --noLinking --header"
  AC_MSG_CHECKING([for NIM options to generate C code])
  f=conftest
  rm -f $f.err $f.nim nimcache/*
  echo "# empty NIM source" > $f.nim
  $NIM2C $f.nim > $f.err 2>&1
  if test $? = 0 -a -s nimcache/$f.h -a -s nimcache/$f.c ; then
    AC_MSG_RESULT([ok])
    rm -f $f.err $f.nim nimcache/*
    rmdir nimcache
  else
    AC_MSG_RESULT([failed])
    cat $f.err
    AC_MSG_ERROR([Command "$NIM2C ..." does not seem to work])
  fi

  dnl MINGW native needs realpath for MIMBLE to work
  if test ".exe" = "$NIMEXE" ; then
    AC_CHECK_PROG([realpath],[realpath],[yes],[no])
    if test yes != "$realpath"; then
      msg="Command 'realpath' is required for NIMBLE"
      AC_MSG_ERROR([$msg to work properly (part if GIT package?)])
    fi
  dnl command hg for NIMBLE on Linux (.exe => not Windows)
  else
    AC_CHECK_PROG([hg],[hg],[yes],[no])
    if test yes != "$hg"; then
      msg="Command 'hg' from MERCURIAL"
      AC_MSG_ERROR([$msg is required by NIMBLE])
    fi
  fi

  dnl need libSSL for NIMBLE on Linux (.exe => not Windows)
  if test ".exe" != "$NIMEXE" ; then
    if test "$cross_compiling" = no; then
      AC_CHECK_LIB([ssl],[SSL_library_init],
                         [ac_nim_cv_ssl=yes],[ac_nim_cv_ssl=no])
      if test "$ac_nim_cv_ssl" != yes; then
        msg="Compatible SSL lib is reqired by NIMBLE"
        inf="on Debian consider installing 'libssl1.0-dev'"
        AC_MSG_ERROR([$msg - $inf])
      fi
    fi
  fi
])


AC_DEFUN([AC_MSG_LOCAL_NIM],[
  case "$use_local_nim" in
  yes) msg="Using local NIM package" ;;
  *)   msg="Using NIM installation from operating system"
  esac
  AC_MSG_NOTICE([$msg])
])

# ---------------------------------------------------------------------------
# End
# ---------------------------------------------------------------------------
