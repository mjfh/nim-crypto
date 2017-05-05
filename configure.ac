# -*- autoconf -*-
#
# $Id$
#
# Blame: Jordan Hrycaj <jordan@teddy-net.com>

AC_PREREQ([2.68])
AC_INIT([nim-crypto],
	[m4_esyscmd_s([sed s/\#// VERSION])],
	[jordan@teddy-net.com])

# list of NIM modules to import via NIMBLE
NIMIMPORT=
AC_SUBST([NIMIMPORT])

# list of direct sub-modules in src/lib
NIMSRC_SUBMOD=
AC_SUBST([NIMSRC_SUBMOD])

AC_CONFIG_HEADERS([conf/config.h])
AC_CONFIG_SRCDIR([acinclude.m4])
AC_CONFIG_INIT([2017-@YEAR@ Mjh-IT Ltd, Cambridge, UK])
AC_CONFIG_MACRO_DIR([m4lib])

AC_LANG(C)
dnl # Enable ISO features if possible. On Linux, setting _XOPEN_SOURCE
dnl # includes POSIX and XPG things.  Set to 500 if Single Unix
dnl # conformance is wanted, to 600 for the upcoming sixth revision.
dnl # AC_DEFINE([_XOPEN_SOURCE],[600],[set minimum standard conformance])

# configuration options
AC_ENABLE_CPU
AC_ENABLE_DEBUG
# AC_DISABLE_UNIT_TESTS
AC_WITHOUT_LOCAL_NIM
AC_WITH_WINE
# AC_WITH_MSWIN_STDIO

# Libtool
LT_PREREQ([2.4])
LT_INIT
AC_SUBST([LIBTOOL_DEPS])
AC_PROG_LIBTOOL

# Checks for programs.
AC_PROG_CC
# AC_PROG_CPP
AC_PROG_CC_C99
# AM_PROG_CC_C_O
# AC_PROG_CC_ASM_INLINE
AC_PROG_GCC_ATTRIBS
AC_PROG_GCC_FWRAPV
# AC_C_RESTRICT
# AC_PROG_INSTALL
AC_PROG_LN_S
AC_PROG_MAKE_SET
AC_PROG_MKDIR_P

# Checks for libraries.
# FIXME: Replace `main' with a function in `-lm':
AC_CHECK_LIB([m],[main])
AC_CHECK_CPU
AC_CHECK_LOCAL_NIM
AC_CHECK_WINE

# Standard/posix and windows support
# AC_HEADERS_POSIX
# AC_HEADERS_WINDOWS

# Verify configuration options
AC_CHECK_DEBUG
# AC_CHECK_UNIT_TESTS
# AC_CHECK_MSWIN_STDIO

# Checks for typedefs, structures, and compiler characteristics.
# AC_CHECK_HEADER_STDBOOL
# AC_TYPE_INT16_T
# AC_TYPE_INT32_T
# AC_TYPE_SIZE_T
# AC_TYPE_UINT16_T
# AC_TYPE_UINT32_T
# AC_TYPE_UINT8_T
# AC_CHECK_INLINE
# AC_CHECK_COMMON_SIZEOF

# Checks for library functions.
# AC_FUNC_MALLOC
# AC_FUNC_REALLOC
# AC_FUNC_VSNPRINTF
# AC_CHECK_FUNCS([gettimeofday memset strstr])

# Makefile path support
AC_SUBST_BASEDIR(boot)
AC_SUBST_BASEDIR(conf)
AC_SUBST_BASEDIR(tools)
AC_SUBST_BASEDIR(src)
AC_SUBST_BASEDIR(src/lib)

AC_CONFIG_FILES([Makefile
		 boot/Makefile
		 boot/nim-compile.sh
		 boot/nim-check.sh
		 boot/nim-cfg.sh

		 src/Makefile
		 src/lib/Makefile
		 src/lib/uecc/Makefile
		 src/lib/chacha/Makefile
		 src/lib/ltc/Makefile
		 src/lib/misc/Makefile
		 src/lib/rnd64d/Makefile
		 src/lib/salsa/Makefile
		 src/lib/spmx/Makefile
		 src/lib/xoro/Makefile
])

# Output, write configs
AC_OUTPUT

# Print configuration
AC_MSG_NOTICE([=============================================================])
if test "$cross_compiling" = yes
then
   AC_MSG_NOTICE([Cross compiling for target: $TARGET_CONFIG_ID])
   AC_MSG_NOTICE([Build system: $BUILD_CONFIG_ID])
   AC_MSG_WINE
else
   AC_MSG_CPU
fi
# AC_MSG_MSWIN_STDIO
AC_MSG_DEBUG
# AC_MSG_UNIT_TESTS
AC_MSG_LOCAL_NIM
AC_MSG_NOTICE([=============================================================])

# End
