# -*- m4 -*-
#
# $Id$
#
# Blame: Jordan Hrycaj <jordan@teddy-net.com>

# ---------------------------------------------------------------------------
# Makefile: force/check for MS-windows stdio (windows/posix %lld madness)
# ---------------------------------------------------------------------------

dnl syntax: _AC_CHECK_MSWIN_STDIO_COMPILE <function>
dnl                                      [action-if-available]
dnl                                      [action-if-missing]
AC_DEFUN([_AC_CHECK_MSWIN_STDIO_COMPILE],[
  AC_REQUIRE([AC_PROG_GCC_WERROR_IMPLICIT])
  AC_REQUIRE([AC_PROG_GCC_WERROR_FORMAT])
  CC_save="$CC"
  CC="$CC $CFLAGS_GCC_WERROR_FORMAT $CFLAGS_GCC_WERROR_IMPLICIT"
  AC_MSG_CHECKING([whether $1() supports "%I64x"])
  AC_COMPILE_IFELSE([AC_LANG_SOURCE([
    AC_INCLUDES_DEFAULT
    AC_INCLUDES_WINDOWS
    [
     void*f(void){$1 ("%I64x", (long long)-1);}
    ]])],[AC_MSG_RESULT([yes]); $2],
	 [AC_MSG_RESULT([no]);  $3])
  CC="$CC_save"
])

dnl syntax: _AC_CHECK_MSWIN_STDIO_RUN     <function>
dnl                                       [action-if-available]
dnl                                       [action-if-missing]
dnl                                       [action-if-xcompiling]
AC_DEFUN([_AC_CHECK_MSWIN_STDIO_RUN],[
  AC_MSG_CHECKING([whether $1() supports "%I64x" and not "llx"])
  AC_RUN_IFELSE([AC_LANG_PROGRAM([
    AC_INCLUDES_DEFAULT
    AC_INCLUDES_WINDOWS
    [
     static char buf [2 * sizeof (long long) + 1];
    ]],[[
     int n, m;
     for (n=0; n < sizeof (buf); n ++) {
       buf [n] = 0;
     }
     $1 (buf, "%I64x", (long long) 0x0123456789);
     for (n=0; n < 10; n ++) {
       if (buf [n] != '0' + n)
         exit (2);
     }
     for (n=0; n < sizeof (buf); n ++) {
       buf [n] = 0;
     }
     $1 (buf, "%llx", (long long) 0x0123456789);
     for (n=m=0; n < 10; n ++) {
       if (buf [n] == '0' + n)
         m ++;
     }
     exit (m != 10);
    ]])],[AC_MSG_RESULT([yes]); $2],
         [AC_MSG_RESULT([no]);  $3],
         [$4])
])

dnl syntax: _AC_CHECK_MSWIN_STDIO_PRI64 <value>
dnl                                     [action-if-available]
dnl                                     [action-if-missing]
dnl                                     [action-if-xcompiling/not-gcc]
AC_DEFUN([_AC_CHECK_MSWIN_STDIO_PRIx64],[
  AC_REQUIRE([AC_PROG_GCC_WERROR_IMPLICIT])
  AC_REQUIRE([AC_PROG_GCC_WERROR_FORMAT])
  AC_INIT_IFGCC([GCC/printf],
    [CC_save="$CC"
     CC="$CC $CFLAGS_GCC_WERROR_FORMAT $CFLAGS_GCC_WERROR_IMPLICIT"
     AC_MSG_CHECKING([whether PRIx64 and $1 both work for printf()])
     AC_COMPILE_IFELSE([AC_LANG_SOURCE([
       AC_INCLUDES_DEFAULT
       AC_INCLUDES_WINDOWS
       [
        void *f (void) {
	  printf ("%" PRIx64 " %" $1, (long long)-1,(long long)-1);
        }
       ]])],[AC_MSG_RESULT([yes]); $2],
            [AC_MSG_RESULT([no]);  $3])
     CC="$CC_save"],
    [AC_MSG_CHECKING([whether PRIx64 is $1])
     AC_RUN_IFELSE([AC_LANG_PROGRAM([
       AC_INCLUDES_DEFAULT
       AC_INCLUDES_WINDOWS
       [
        static char buf [] = PRIx64 ;
        static char trg [] = $1 ;
       ]],[[
        int n = 0 ;
        do {
          if (trg [n] != buf [n])
            exit (1);
        }
        while (buf [n ++] != 0);
        exit (0);
       ]])],[AC_MSG_RESULT([yes]); $2],
            [AC_MSG_RESULT([no]);  $3],
            [$4])])
])

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------

AC_DEFUN([AC_WITH_MSWIN_STDIO],[
  AC_ARG_WITH([mswin-stdio],
    [AC_HELP_STRING([--with-mswin-stdio],
      [force MS-Windows like printf()/scanf() format strings])],
    [case "$withval" in
     yes|no) have_mswin_stdio=$withval ;;
     *)      msg="Unsupported option argument"
             AC_MSG_NOTICE([$msg "--with-mswin-stdio=$withval"])
     esac],
    [have_mswin_stdio=any])
])


AC_DEFUN([AC_CHECK_MSWIN_STDIO],[
  AC_CHECK_HEADERS([stdio.h inttypes.h])
  dnl
  AC_LANG_PUSH([C])
  dnl
  AC_INIT_IFGCC([GCC/printf],
    [AC_INIT_IFMINGW([MinGW ANSI/stdio],
      [if test $have_mswin_stdio != yes; then
         AC_DEFINE([__USE_MINGW_ANSI_STDIO],[1],
           [MinGW only: use ANSI rather than Windows stdio])
       fi])
     _AC_CHECK_MSWIN_STDIO_COMPILE([printf],
      [ok=yes],
      [ok=no])],
    [_AC_CHECK_MSWIN_STDIO_RUN([sprintf],
      [ok=yes],
      [ok=no],
      [AC_MSG_ERROR([Cross compiling: printf()/fmt support unknown!])])])
  dnl
  msg="MS-Windows/Stdio"
  case $have_mswin_stdio:$ok in
  yes:yes|no:no)
         have_mswin_stdio="$have_mswin_stdio (configured)" ;;
  any:*) have_mswin_stdio=$ok ;;
  yes:*) AC_MSG_ERROR([$msg not available, try --without-mswin-stdio]) ;;
  no:*)  AC_MSG_ERROR([Only $msg available, try --with-mswin-stdio])
  esac
  dnl
  case $have_mswin_stdio in
  y*) AC_DEFINE([HAVE_MSWIN_STDIO],[1],
        [Define if you have a MS formats for printf().])
      msg="be accepted in Windows mode"
      _AC_CHECK_MSWIN_STDIO_PRIx64(["I64x"],,
        [AC_MSG_ERROR(["I64x" must $msg])])
dnl   _AC_CHECK_MSWIN_STDIO_PRIx64(["llu"],
dnl     [AC_MSG_ERROR(["llu" must NOT $msg])])
      ;;
  *)  AC_INIT_IFAMD64([Checking printf()],,[
      msg="be accepted in ANSI mode"
        _AC_CHECK_MSWIN_STDIO_PRIx64(["llu"],,
          [AC_MSG_ERROR(["llu" must $msg])])
dnl     _AC_CHECK_MSWIN_STDIO_PRIx64(["I64"],
dnl       [AC_MSG_ERROR(["I64" must NOT $msg])])
        ])
  esac
  dnl
  AC_LANG_POP([C])
])


AC_DEFUN([AC_MSG_MSWIN_STDIO],[
  case "$have_mswin_stdio" in
  yes) msg="Using MS-Windows/stdio formats for printf()" ;;
  *)   msg="Using ANSI/stdio formats for printf()"
  esac
  AC_MSG_NOTICE([$msg])
])

# ---------------------------------------------------------------------------
# End
# ---------------------------------------------------------------------------
