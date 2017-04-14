# ===========================================================================
#       http://www.gnu.org/software/autoconf-archive/ax_asm_inline.html
# ===========================================================================
#
# SYNOPSIS
#
#   AX_ASM_INLINE()
#
# DESCRIPTION
#
#   Tests for C compiler support of inline assembly instructions. If inline
#   assembly is supported, this macro #defines ASM_INLINE to be the
#   appropriate keyword.
#
# LICENCE
#
#   Copyright (c) 2008 Alan Woodland <ajw05@aber.ac.uk>
#   Copyright (c) 2009 Rhys Ulerich <rhys.ulerich@gmail.com>
#
#   Copying and distribution of this file, with or without modification, are
#   permitted in any medium without royalty provided the copyright notice
#   and this notice are preserved. This file is offered as-is, without any
#   warranty.

# Changes made by jordan:
#   macro name: AC_PROG_CC_ASM_INLINE
#

#serial 2

AC_DEFUN([AC_PROG_CC_ASM_INLINE], [
  AC_LANG_PUSH([C])
  AC_MSG_CHECKING(for inline assembly style)
  ax_asm_inline_keywords="__asm__ __asm asm none"
  for ax_asm_inline_keyword in $ax_asm_inline_keywords; do
     case $ax_asm_inline_keyword in
     none)
        ac_prog_cc_asm_inline=none
        break ;;
     *) AC_COMPILE_IFELSE([AC_LANG_SOURCE([
           [
            #include <stdlib.h>
            static void foo(void) {
            ] $ax_asm_inline_keyword [("");
            exit(1);
            }
           ]])],
           [ac_prog_cc_asm_inline=$ax_asm_inline_keyword
            break],
           [ac_prog_cc_asm_inline=none])
     esac
  done
  if test "$ac_prog_cc_asm_inline" != "none"; then
    AC_DEFINE_UNQUOTED([ASM_INLINE],[$ac_prog_cc_asm_inline],
      [the keyword for inline assembly if supported by compiler])
  fi
  AC_MSG_RESULT($ac_prog_cc_asm_inline)
  AC_LANG_POP([C])
])

# ---------------------------------------------------------------------------
# End
# ---------------------------------------------------------------------------
