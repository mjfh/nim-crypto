# -*- m4 -*-
#
# $Id$
#
# Blame: Jordan Hrycaj <jordan@teddy-net.com>

# ---------------------------------------------------------------------------
# Find commands on operating system, extends AC_CHECK_PROG macro
# ---------------------------------------------------------------------------

AC_DEFUN([AC_CHECK_PROGPATH],[
dnl syntax: $1 -- var-name
dnl         $2 -- command-name
dnl         $3 -- [path]
dnl         $4 -- [action if found]
dnl         $5 -- [action if not found]
dnl
  dnl $3 needs to be expanded first, nested `` is not necessarily available
  m4_ifvaln([$3],[ac_check_cmdpath_path="$3"
    ac_check_cmdpath_path=`echo $ac_check_cmdpath_path | ${AWK:-awk} -F: '
      [$]1 ~ /\/bin$/  { p2 = substr([$]1,1,length ([$]1)-3) "sbin" }
      [$]1 ~ /\/sbin$/ { p2 = substr([$]1,1,length ([$]1)-4)  "bin" }
      END {
	 ORS = ":"
	 print [$]1
	 if (p2 != "") print p2
	 for (n=2; n<=NF; n++) {print $n}
      }'`
    ac_check_cmdpath_save="$PATH"
    PATH="$ac_check_cmdpath_path"])

  dnl WARNING: check configure script to verify the full path name
  AC_CHECK_PROG([$1],[$2],[$as_dir/$ac_word$ac_exec_ext])

  m4_ifvaln([$3],[PATH="$ac_check_cmdpath_save"])

  m4_ifvaln([$4$5],[eval ac_check_cmdpath_var=\"\$$ac_check_cmdpath_var\"])
  m4_ifvaln([$4],  [test -n "$ac_check_cmdpath_var" && { $4; }])
  m4_ifvaln([$5],  [test -z "$ac_check_cmdpath_var" && { $5; }])
])

AC_DEFUN([AC_CHECK_CMDPATH],[
dnl syntax: $1 -- command-name
dnl         $2 -- [path]
dnl         $3 -- [action if found]
dnl         $4 -- [action if not found]
dnl
dnl result: CMDPATH_`uc(<command-name>)`
  m4_pushdef([VAR],CMDPATH_[]m4_translit([$1],[a-z -],[A-Z__]))
  AC_CHECK_PROGPATH(m4_defn([VAR]),[$1],[$2],[$3],[$4])
  m4_popdef([VAR])
])

# ---------------------------------------------------------------------------
# end
# ---------------------------------------------------------------------------
