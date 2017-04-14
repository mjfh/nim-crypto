# -*- m4 -*-
#
# $Id$
#
# Blame: Jordan Hrycaj <jordan@teddy-net.com>

# ---------------------------------------------------------------------------
# config.h & macros: date, time, revision, kernel/os symbols
# ---------------------------------------------------------------------------

dnl Syntax: _AC_INIT_IFCONDITION([variable],            -- $1
dnl                              [comment])             -- $2
dnl                              [true/false-fail-msg], -- $3
dnl                              [action-if-yes],       -- $4
dnl                              [action-if-not-yes],   -- $5
dnl                              [action-if-unset],     -- $6
AC_DEFUN([_AC_INIT_IFCONDITION],[
  m4_ifvaln([$3],[# BEGIN $3])dnl
  if test "$[]$1" = yes; then
    m4_ifvaln([$4],[$4],[m4_ifvaln([$3],
      [AC_MSG_NOTICE([$3 ignored on $2])],[:])])dnl
    m4_ifvaln([$6],[elif test -z "$1"; then $6])
  else
    m4_ifvaln([$5],[$5],[m4_ifvaln([$3],
      [AC_MSG_NOTICE([$3 ignored unless $2])],[:])])dnl
  fi m4_ifvaln([$3],[# END $3],[# $1])dnl
])

dnl Syntax: AC_INIT_IFXCOMPILE([true/false-fail-msg],
dnl                            [action-if-true],
dnl                            [action-if-false])
AC_DEFUN([_AC_INIT_IFXCOMPILE],[
  _AC_INIT_IFCONDITION([cross_compiling],[cross compiling],$@)
])

AC_DEFUN([_AC_INIT_WINDOWS],[
  AC_DEFINE([_WINDOWS],      [1],[compiling for windows])
  AC_DEFINE([PATH_DELIM], ['\\'],[OS path delimiter])
  AC_DEFINE([OTHER_DELIM], ['/'],[path delimiter for other OSes])
  AC_CHECK_TOOL([WINDRES],[windres])
])

AC_DEFUN([_AC_INIT_MINGW32],[
  AC_MSG_NOTICE([MinGW Windows/32bit compiling])
  _AC_INIT_IFXCOMPILE([MinGW 32bit],
    [AC_DEFINE([CROSS_COMPILING],[1],[cross compiler activated])])
  _AC_INIT_WINDOWS()
  AC_DEFINE([_WIN32],   [1],[32bit Windows target])
  AC_DEFINE([_MINGW32], [1],[32bit minimalist Gnu Windows compiler])
  target_mingw32=yes
  target_mingw=yes
  target_i386=yes
])

AC_DEFUN([_AC_INIT_MINGW64],[
  AC_MSG_NOTICE([MinGW Windows/64bit compiling])
  _AC_INIT_IFXCOMPILE([MinGW 64bit],
    [AC_DEFINE([CROSS_COMPILING],[1],[cross compiler activated])],
    [AC_MSG_NOTICE([echo using native MinGW 64bit])])
  _AC_INIT_WINDOWS()
  AC_DEFINE([_WIN64],   [1],[64bit Windows target])
  AC_DEFINE([_X64WIN32],[1],[64bit Windows target on 32bit host])
  AC_DEFINE([_MINGW64], [1],[64bit minimalist Gnu Windows compiler])
  target_mingw64=yes
  target_mingw=yes
  target_amd64=yes
])

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------

AC_DEFUN([AC_BUILDENV_INIT],[
  AC_REQUIRE([AC_PROG_CC])dnl
  AC_REQUIRE([AC_PROG_LIBTOOL])dnl
dnl
  BUILD_CONFIG_ID=$build_cpu-$build_vendor-$build_os
  AC_SUBST(BUILD_CONFIG_ID)dnl
dnl
  TARGET_CONFIG_ID=$host_cpu-$host_vendor-$host_os
  AC_SUBST(TARGET_CONFIG_ID)dnl
dnl
  TARGET_CONFIG_HOST=${host_alias:-$host_cpu-$host_os}
  AC_SUBST(TARGET_CONFIG_HOST)dnl
dnl
  AC_DEFINE_UNQUOTED([TARGET_CONFIG_ID],
                     ["$TARGET_CONFIG_ID"],
                     [the target system type (when cross compiling)])
dnl
  target_i386=no
  target_amd64=no
  case $host_cpu in
  i?86) AC_DEFINE([TARGET_CONFIG_I386],[1],
                  [target system runs on a x86 cpu])
	;;
  x86_64) AC_DEFINE([TARGET_CONFIG_AMD64],[1],
                    [target system runs on a amd64 cpu])
	target_amd64=yes
  esac
dnl
  _AC_INIT_IFXCOMPILE([],

    [if test -z "$ac_cross_dir_base"; then
       ac_cross_bin_base=`dirname $lt_cv_path_LD`
       ac_cross_dir_base=`dirname $ac_cross_bin_base`
       dnl
       AC_MSG_CHECKING([for bin directories])
       CROSSBIN_PATH=`find "$ac_cross_bin_base" -type d -name bin \
			       -print 2>/dev/null | tr '\n' ':'`
       case $CROSSBIN_PATH in ???*)yes=ok;;*)yes=missing;esac
       AC_MSG_RESULT([$yes])
       dnl
       AC_MSG_CHECKING([for lib directories])
       CROSSLIB_PATH=`find "$ac_cross_dir_base" -type d -name lib \
			       -print 2>/dev/null | tr '\n' ':'`
       case $CROSSLIB_PATH in ???*)yes=ok;;*)yes=missing;esac
       AC_MSG_RESULT([$yes])
     fi],

    [if test -z "$ac_cross_dir_base"; then
       ac_cross_dir_base=/usr
       CROSSLIB_PATH=
       CROSSBIN_PATH=
     fi
     SUBSYS_WINDOWS_CFLAGS=
     dnl
     if test "x$build_os" != "x$host_os"; then
       msg=
       if test -f /usr/share/binfmts/wine ; then
          case `dpkg-architecture -qDEB_HOST_GNU_TYPE 2>/dev/null` in
          *-*-*) msg="\"update-binfmts --disable wine\" or "
          esac
       fi
       mss="activated although it should - compiler or libraries missing"
       AC_MSG_ERROR([Cross compiling is not $mss?
                   You might need to disable wine auto/exec like:
                   $msg\"chmod 0 /var/lib/binfmts/wine\"])
     fi],

    [msg="Cannot decide about cross compiling yet"
     pfx=AC
     AC_MSG_ERROR([$msg - ${pfx}_$1 has been invoked too early])])dnl
dnl
  target_mingw32=no
  target_mingw64=no
  target_mingw=no
  case $TARGET_CONFIG_ID in
  amd64-*-mingw32*|x86_64-*-mingw32*)
     _AC_INIT_MINGW64([$TARGET_CONFIG_ID]) ;;dnl
  i?86-*-mingw32*)
     _AC_INIT_MINGW32([$TARGET_CONFIG_ID]) ;;dnl
  *) AC_DEFINE([PATH_DELIM],  ['/'],[OS path delimiter])dnl
     AC_DEFINE([OTHER_DELIM],['\\'],[path delimiter for other OSes])dnl
  esac
dnl
  target_cygwin=
  case $TARGET_CONFIG_ID in *-cygwin)
      AC_DEFINE([_CYGWIN],[1],[Cygwin is used])dnl
      target_cygwin=yes
  esac
dnl
  AH_TEMPLATE([_VC_WINDOWS],[defined on a Ms-VC++/Visual Studio environment])
dnl
  AM_CONDITIONAL([USE_I386],       [test "$target_i386"     = yes])dnl
  AM_CONDITIONAL([USE_AMD64],      [test "$target_amd64"    = yes])dnl
  AM_CONDITIONAL([USE_CYGWIN],     [test "$target_cygwin"   = yes])dnl
  AM_CONDITIONAL([USE_MINGW64],    [test "$target_mingw64"  = yes])dnl
  AM_CONDITIONAL([USE_MINGW32],    [test "$target_mingw32"  = yes])dnl
  AM_CONDITIONAL([USE_MINGW],      [test "$target_mingw"    = yes])dnl
  AM_CONDITIONAL([CROSS_COMPILING],[test "$cross_compiling" = yes])dnl

  if test "$cross_compiling" = yes; then
    AC_DEFINE([CROSS_COMPILING],[1],[cross compiling])
  fi
])

dnl Syntax: AC_INIT_IFAM64([true/false-fail-msg],
dnl                        [action-if-true],
dnl                        [action-if-false])
AC_DEFUN([AC_INIT_IFAMD64],[
  AC_REQUIRE([AC_BUILDENV_INIT])dnl
  _AC_INIT_IFCONDITION([target_amd64],[AMD64],$@)
])

dnl Syntax: AC_INIT_IFCYGWIN([true/false-fail-msg],
dnl                          [action-if-true],
dnl                          [action-if-false])
AC_DEFUN([AC_INIT_IFCYGWIN],[
  AC_REQUIRE([AC_BUILDENV_INIT])dnl
  _AC_INIT_IFCONDITION([target_cygwin],[CYGWIN],$@)
])

dnl Syntax: AC_INIT_IFXCOMPILE([true/false-fail-msg],
dnl                            [action-if-true],
dnl                            [action-if-false])
AC_DEFUN([AC_INIT_IFXCOMPILE],[
  AC_REQUIRE([AC_BUILDENV_INIT])dnl
  _AC_INIT_IFXCOMPILE($@)
])

dnl Syntax: AC_INIT_IFGCC([true/false-fail-msg],
dnl                       [action-if-true],
dnl                       [action-if-false])
AC_DEFUN([AC_INIT_IFGCC],[
  AC_REQUIRE([AC_BUILDENV_INIT])dnl
  _AC_INIT_IFCONDITION([GCC],[GNU cc],$@)
])

dnl Syntax: AC_INIT_IFMINGW([true/false-fail-msg],
dnl                         [action-if-true],
dnl                         [action-if-false])
AC_DEFUN([AC_INIT_IFMINGW],[
  AC_REQUIRE([AC_BUILDENV_INIT])dnl
  _AC_INIT_IFCONDITION([target_mingw],[MinGW i386 or amd64 gcc],$@)
])

AC_DEFUN([AC_INIT_OSTYPE],[
  AC_INIT_IFXCOMPILE([],
    [case "$TARGET_CONFIG_ID" in
     *-*-mingw32*)
        AC_DEFINE([OS_KERNEL_NAME],["WINDOWS"],[target operating system]);;
     *) AC_MSG_ERROR([Cross compiler OS for $TARGET_CONFIG_ID unsupported])
     esac],
    [uname_s=`uname -s|tr '@<:@a-z@:>@' '@<:@A-Z@:>@'|
                       sed 's/@<:@^A-Z0-9@:>@/_/g'`
     case "$uname_s" in
     CYGWIN_*) uname_s=CYGWIN;;
     esac
     if test -n "$uname_s"; then
       AC_DEFINE_UNQUOTED([OS_KERNEL_NAME],["$uname_s"],
		          [target operating system])
       uname_r=`uname -r`
       if test -n "$uname_r"; then
         AC_DEFINE_UNQUOTED([OS_KERNEL_RELEASE], ["$uname_r"],
			    [target operating system kernel version])
       fi
     fi])
])

# ---------------------------------------------------------------------------
# End
# ---------------------------------------------------------------------------
