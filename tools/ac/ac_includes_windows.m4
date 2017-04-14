# -*- m4 -*-
#
# $Id$
#
# Blame: Jordan Hrycaj <jordan@teddy-net.com>

# ---------------------------------------------------------------------------
# Helper: include windows files
# ---------------------------------------------------------------------------

AC_DEFUN([_AC_INCLUDES_WINDOWS_SETUP],[
  ac_init_winheaders="
# ifdef HAVE_WINSOCK2_H_FIRST
#  include <winsock2.h>
#  ifdef HAVE_WS2TCPIP_H
#   include <ws2tcpip.h>
#  endif
# endif
# ifdef HAVE_WINDOWS_H
#  define WIN32_LEAN_AND_MEAN
#  include <windows.h>
# endif
# ifdef HAVE_WINBASE_H
#  include <winbase.h>
# endif
# ifdef HAVE_WINSOCK2_H
#  include <winsock2.h>
# endif
# ifdef HAVE_WS2TCPIP_H
#  include <ws2tcpip.h>
# endif
# ifdef HAVE_PSAPI_H
#  include <psapi.h>
# endif
"
])

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------

dnl Syntax: AC_INCLUDES_WINDOWS([prepend-and-remember])
AC_DEFUN([AC_INCLUDES_WINDOWS],[
  AC_REQUIRE([_AC_INCLUDES_WINDOWS_SETUP])dnl
  m4_ifvaln([$1],[ac_init_winheaders="$1])
$ac_init_winheaders
m4_ifvaln([$1],["])])

# ---------------------------------------------------------------------------
# End
# ---------------------------------------------------------------------------
