# -*- m4 -*-
#
# $Id$
#
# Blame: Jordan Hrycaj <jordan@teddy-net.com>

# ---------------------------------------------------------------------------
# config.h: check for standard windows headers
# ---------------------------------------------------------------------------

AC_DEFUN([AC_HEADERS_WINDOWS],[
  AC_INIT_IFCYGWIN([Generic win32/64 headers],,[
    AC_CHECK_HEADERS([crtdefs.h direct.h mbstring.h io.h process.h])
    AC_CHECK_HEADERS([windef.h windows.h])
    dnl
    AC_CHECK_HEADERS([psapi.h malloc.h winioctl.h winbase.h],,,
                     [AC_INCLUDES_WINDOWS])
])])

# ---------------------------------------------------------------------------
# End
# ---------------------------------------------------------------------------
