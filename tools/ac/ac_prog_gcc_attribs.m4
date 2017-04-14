# -*- m4 -*-
#
# $Id$
#
# Blame: Jordan Hrycaj <jordan@teddy-net.com>
#
# inspired by http://autoconf-archive.cryp.to/ax_gcc_warn_unused_result.html
#

# ---------------------------------------------------------------------------
# config.h: HAVE_GCC_ATTRIBUTE_<attribute> and FUNCTION_ATTRIBUTE_<mode>
# ---------------------------------------------------------------------------

dnl syntax: _AC_PROG_GCC_FN_ATTRIBUTE_TEST <format-expression>
dnl                                        <attribute-arg>
dnl                                        [action-if-available]
dnl                                        [action-if-missing]
AC_DEFUN([_AC_PROG_GCC_FN_ATTRIBUTE_TEST],[
  AC_REQUIRE([AC_PROG_GCC_WERROR_ATTRIBUTES])
  CC_save="$CC"
  CC="$CC $CFLAGS_GCC_WERROR_ATTRIBUTES"
  AC_MSG_CHECKING([for GCC supporting __attribute__(($2))])
  AC_COMPILE_IFELSE([AC_LANG_SOURCE([
    AC_INCLUDES_DEFAULT
    [
     void*f(int,$1)__attribute__(($2));
     void*f(int i,$1){exit(i);}
    ]])],[AC_MSG_RESULT([yes]); $3],
	 [AC_MSG_RESULT([no]);  $4])
  CC="$CC_save"
])

dnl syntax: _AC_PROG_GCC_VAR_ATTRIBUTE_TEST <attribute-expression>
dnl                                         <attribute-arg>
dnl                                         [action-if-available]
dnl                                         [action-if-missing]
AC_DEFUN([_AC_PROG_GCC_VAR_ATTRIBUTE_TEST],[
  AC_REQUIRE([AC_PROG_GCC_WERROR_ATTRIBUTES])
  CC_save="$CC"
  CC="$CC $CFLAGS_GCC_WERROR_ATTRIBUTES"
  AC_MSG_CHECKING([for GCC supporting __attribute__(($2))])
  AC_COMPILE_IFELSE([AC_LANG_SOURCE([
    AC_INCLUDES_DEFAULT
    [
      void*f(void){$1 __attribute__(($2));}
    ]])],[AC_MSG_RESULT([yes]); $3],
         [AC_MSG_RESULT([no]);  $4])
  CC="$CC_save"
])

dnl syntax: _AC_PROG_GCC_HAS_BUILTIN_TEST <method>
dnl                                       [action-if-available]
dnl                                       [action-if-missing]
AC_DEFUN([_AC_PROG_GCC_HAS_BUILTIN_TEST],[
  AC_MSG_CHECKING([for GCC supporting __builtin_$1()])
  AC_COMPILE_IFELSE([AC_LANG_SOURCE([
    AC_INCLUDES_DEFAULT
    [void*f(void){
#    ifdef __has_builtin
#     if __has_builtin(__builtin_$1)
       exit (0);
       __builtin_$1();
#     else
#      error no such builtin: $1
#     endif
#    else
       exit (0);
       __builtin_$1();
#    endif
     exit(1);}
    ]])],[AC_MSG_RESULT([yes]); $2],
	 [AC_MSG_RESULT([no]);  $3])
])

AC_DEFUN([_AC_PROG_GCC_FN_ATTRIBUTE_FMT23_TEST],[
  _AC_PROG_GCC_FN_ATTRIBUTE_TEST([char*a,...],[format($1,2,3)],m4_shift($@))
])

AC_DEFUN([_AC_PROG_GCC_FN_ATTRIBUTE_FMT20_TEST],[
  _AC_PROG_GCC_FN_ATTRIBUTE_TEST([char*a,...],[format($1,2,0)],m4_shift($@))
])

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------

AC_DEFUN([AC_PROG_GCC_ATTRIBS],[
  NOTREACHED="/* n/a */"
  AC_INIT_IFGCC([GCC compile time attributes],
    [GCC_VARIANT=`echo "$CC"|sed -e 's/^.*\///' -e 's/ .*//'`
     GCC_VERSION=`$CC --version 2>/dev/null|${TR:-tr} ' ' '\n'|sed \
	-e '/^@<:@^0-9@:>@/d'	\
	-e 's/@<:@^0-9@:>@*$//'	\
	-e q`
     AC_DEFINE_UNQUOTED(_GCC_VARIANT, ["$GCC_VARIANT"],
	[Variant of GCC compiler])
     AC_DEFINE_UNQUOTED(_GCC_VERSION, ["$GCC_VERSION"],
	[GCC version: major-minor-patchlevel])
     dnl
     if test -n "$GCC_VERSION" ; then
       GCC_RECENT=1
     fi
     unset GCC_LEGACY_MODE
     case "$GCC_VARIANT" in *cc*)
     case "$GCC_VERSION" in @<:@12@:>@.*|3.@<:@1-5@:>@*)
        GCC_LEGACY_MODE=1
	unset GCC_RECENT
        AC_DEFINE(_GCC_LEGACY_MODE, [1], [Old version of GCC compiler])
     esac
     esac
     AM_CONDITIONAL([USE_GCC_LEGACY_MODE],[test -n "$GCC_LEGACY_MODE"])
     AM_CONDITIONAL([USE_GCC_RECENT],     [test -n "$GCC_RECENT"])
     dnl
     AC_LANG_PUSH([C])
     dnl
     if test -z "$GCC_LEGACY_MODE" ; then
       _AC_PROG_GCC_HAS_BUILTIN_TEST([unreachable],
          [NOTREACHED="__builtin_unreachable ()"])
       dnl
       _AC_PROG_GCC_FN_ATTRIBUTE_TEST([int a,int b],[alloc_size(2,3)],
         [AC_DEFINE([HAVE_GCC_ATTRIBUTE_ALLOC_SIZE],[1],
            [value of particular gcc attribute])])
     fi
     dnl
     _AC_PROG_GCC_FN_ATTRIBUTE_TEST([int a],[noreturn],
        [AC_DEFINE([HAVE_GCC_ATTRIBUTE_NORETURN],[1],
	   [value of particular "noreturn" gcc attribute])])
     dnl
     _AC_PROG_GCC_FN_ATTRIBUTE_TEST([int a],[const],
        [AC_DEFINE([HAVE_GCC_ATTRIBUTE_CONST],[1],
	   [value of particular "const" gcc attribute])])
     dnl
     _AC_PROG_GCC_FN_ATTRIBUTE_TEST([int a],[pure],
        [AC_DEFINE([HAVE_GCC_ATTRIBUTE_PURE],[1],
	   [value of particular "pure" gcc attribute])])
     dnl
     _AC_PROG_GCC_FN_ATTRIBUTE_TEST([int a],[malloc],
        [AC_DEFINE([HAVE_GCC_ATTRIBUTE_MALLOC],[1],
           [value of particular gcc attribute])])
     dnl
     _AC_PROG_GCC_VAR_ATTRIBUTE_TEST([int a],[deprecated],
        [AC_DEFINE([HAVE_GCC_ATTRIBUTE_DEPRECATED],[1],
           [value of particular gcc attribute])])
     dnl
     _AC_PROG_GCC_FN_ATTRIBUTE_TEST([int*a,int*b,int c],[nonnull(2,3)],
        [AC_DEFINE([HAVE_GCC_ATTRIBUTE_NONNULL],[1],
           [value of particular "nonnull(..)" gcc attribute])])
     dnl
     _AC_PROG_GCC_FN_ATTRIBUTE_FMT23_TEST([printf],
        [AC_DEFINE([HAVE_GCC_ATTRIBUTE_FORMAT_PRINTF],[1],
	   [value of particular gcc attribute])])
     dnl
     _AC_PROG_GCC_FN_ATTRIBUTE_FMT23_TEST([gnu_printf],
        [AC_DEFINE([HAVE_GCC_ATTRIBUTE_FORMAT_GNU_PRINTF],[1],
           [value of particular gcc attribute])])
     dnl
     _AC_PROG_GCC_FN_ATTRIBUTE_FMT20_TEST([strftime],
        [AC_DEFINE([HAVE_GCC_ATTRIBUTE_FORMAT_STRFTIME],[1],
	   [value of particular gcc attribute])])
     dnl
     AC_INIT_IFMINGW([MS/VC function attributes],
       [_AC_PROG_GCC_FN_ATTRIBUTE_FMT23_TEST([ms_printf],
          [AC_DEFINE([HAVE_GCC_ATTRIBUTE_FORMAT_MS_PRINTF],[1],
             [value of particular gcc attribute])])
        _AC_PROG_GCC_FN_ATTRIBUTE_FMT20_TEST([ms_strftime],
          [AC_DEFINE([HAVE_GCC_ATTRIBUTE_FORMAT_MS_STRFTIME],[1],
             [value of particular gcc attribute])])])
     dnl
     AC_LANG_POP([C])
     dnl
     AH_TEMPLATE([HAVE_VCWIN_ATTRIBUTE_NORETURN],[VC++/VStudio feature])
   ])
   dnl
   AC_DEFINE_UNQUOTED([__NOTREACHED__],[$NOTREACHED],
     [debug/optimiser directive])
])

# ---------------------------------------------------------------------------
# End
# ---------------------------------------------------------------------------
