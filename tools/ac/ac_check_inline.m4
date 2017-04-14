# -*- m4 -*-
#
# $Id$
#
# Blame: Jordan Hrycaj <jordan@teddy-net.com>

# ---------------------------------------------------------------------------
# Check for C compiler inline support
# ---------------------------------------------------------------------------

AC_DEFUN_ONCE([AC_CHECK_INLINE],[
    AC_C_INLINE

     if test "$ac_cv_c_inline" != no ; then
       AC_DEFINE(HAVE_INLINE,1,[directive "inline" is supported])
       AC_SUBST(HAVE_INLINE)
     fi
])

# ---------------------------------------------------------------------------
# End
# ---------------------------------------------------------------------------
