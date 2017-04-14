# -*- m4 -*-
#
# $Id$
#
# Blame: Jordan Hrycaj <jordan@teddy-net.com>

# ---------------------------------------------------------------------------
# config.h: sizeof()s
# ---------------------------------------------------------------------------

AC_DEFUN([_AC_CHECK_COMMON_SIZEOF_MINGW32],[
  AC_DEFINE([SIZEOF_INT],[4],
	    [size of "int" as computed by sizeof()])
  AC_DEFINE([SIZEOF_UNSIGNED],[4],
	    [size of "unsigned" as computed by sizeof()])
  AC_DEFINE([SIZEOF_SHORT],[2],
	    [size of "short" as computed by sizeof()])
  AC_DEFINE([SIZEOF_LONG],[4],
	    [size of "long" as computed by sizeof()])
  AC_DEFINE([SIZEOF_LONG_LONG],[8],
	    [size of "long long" as computed by sizeof()])
  AC_DEFINE([SIZEOF_WCHAR_T],[2],
	    [size of "wchar_t" as computed by sizeof()])
  AC_DEFINE([SIZEOF_SSIZE_T],[0],
	    [size of "ssize_t" as computed by sizeof()])
  AC_DEFINE([SIZEOF_VOIDP],[$1],
	    [size of "void*" as computed by sizeof()])
  AC_DEFINE([SIZEOF_SIZE_T],[$1],
	    [size of "size_t" as computed by sizeof()])
  AC_DEFINE([SIZEOF_TIME_T],[$1],
	    [size of "time_t" as computed by sizeof()])
])

AC_DEFUN([AC_CHECK_COMMON_SIZEOF],[
  AC_TYPE_INT8_T
  AC_TYPE_INT16_T
  AC_TYPE_INT32_T
  AC_TYPE_INT64_T
  AC_TYPE_LONG_LONG_INT
dnl
  AC_TYPE_UINT8_T
  AC_TYPE_UINT16_T
  AC_TYPE_UINT32_T
  AC_TYPE_UINT64_T
  AC_TYPE_UNSIGNED_LONG_LONG_INT
dnl
  AC_TYPE_SIZE_T
  AC_TYPE_SSIZE_T
  AC_TYPE_UID_T
dnl
  AC_INIT_IFXCOMPILE([],

    [case "$TARGET_CONFIG_ID" in
     amd64-*-mingw32*|x86_64-*-mingw32*)
         _AC_CHECK_COMMON_SIZEOF_MINGW32(8);;
     i?86-*-mingw32*)
         _AC_CHECK_COMMON_SIZEOF_MINGW32(4);;
     *)  AC_MSG_ERROR([Cross compiler for $TARGET_CONFIG_ID unsupported])
     esac],

    [AC_CHECK_SIZEOF([int])
     AC_CHECK_SIZEOF([unsigned])
     AC_CHECK_SIZEOF([short])
     AC_CHECK_SIZEOF([long])
     AC_CHECK_SIZEOF([long long])
     AC_CHECK_SIZEOF([wchar_t])
     AC_CHECK_SIZEOF([ssize_t])
     AC_CHECK_SIZEOF([size_t])
     AC_CHECK_SIZEOF([time_t])
     AC_CHECK_SIZEOF([void*])])
])

# ---------------------------------------------------------------------------
# End
# ---------------------------------------------------------------------------
