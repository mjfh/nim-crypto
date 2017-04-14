# -*- m4 -*-
#
# $Id$
#
# Blame: Jordan Hrycaj <jordan@teddy-net.com>

# ---------------------------------------------------------------------------
# Makefile.am: XXX_DIR
# ---------------------------------------------------------------------------

AC_DEFUN([_AC_SUBST_BASEDIR],[
  $1=$BASE_DIR/$2
  AC_SUBST($1)
])

AC_DEFUN([AC_SUBST_BASEDIR],[
  if test -z "$BASE_DIR" ; then
     if which realpath >/dev/null 2>&1; then
       BASE_DIR=`realpath "$ac_pwd"`
     else
       BASE_DIR="$ac_pwd"
     fi
     case "$BASE_DIR" in @<:@A-Za-z@:>@:/*)
       BASE_DIR=`echo $BASE_DIR|sed -e 's/^.://'`
     esac
     AC_SUBST([BASE_DIR])
  fi
  _AC_SUBST_BASEDIR(m4_translit(m4_bpatsubst([$1],[/]),[a-z],[A-Z])_DIR,$1)
])

# ---------------------------------------------------------------------------
# End
# ---------------------------------------------------------------------------
