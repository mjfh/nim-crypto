# -*- nim -*-
#
# $Id$
#
# Copyright (c) 2017 Jordan Hrycaj <jordan@teddy-net.com>
# All rights reserved.
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted.
#
# The author or authors of this code dedicate any and all copyright interest
# in this code to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and successors.
# We intend this dedication to be an overt act of relinquishment in
# perpetuity of all present and future rights to this code under copyright
# law.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#

import
  os, sequtils, strutils, macros

# ----------------------------------------------------------------------------
# Compiler
# ----------------------------------------------------------------------------

template getCwd: string =
  instantiationInfo(-1, true).filename.parentDir

const
  cwd       = getCwd                               # starts with current ..
  D         = cwd[2 * (cwd[1] == ':').ord]         # .. DirSep, may differ ..
  srcIncDir = cwd & D & "headers"                  # .. from target DirSe
  srcExtDir = cwd & D & "crypt"
  stdCcFlgs = "-I " & srcIncDir

when isMainModule:
  const ccFlags = stdCcFlgs
else:
  const ccFlags = stdCcFlgs & " -DNO_LTC_TEST"

{.passC: ccFlags.}

{.compile: srcExtDir & D & "ltc_crypt-const.c".}


# ----------------------------------------------------------------------------
# Interface
# ----------------------------------------------------------------------------

const
  isCryptOk*             =  0
  isCryptBufferOverflow* =  6
  isCryptInvalidArg*     = 16
  isCryptHashOverflow*   = 25
  ltcFrtaPools*          = 32

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:

  type
    LtcConst = enum # copied from <tomcrypt.h>
      CRYPT_OK = 0,
      CRYPT_ERROR, CRYPT_NOP, CRYPT_INVALID_KEYSIZE,
      CRYPT_INVALID_ROUNDS, CRYPT_FAIL_TESTVECTOR, CRYPT_BUFFER_OVERFLOW,
      CRYPT_INVALID_PACKET, CRYPT_INVALID_PRNGSIZE, CRYPT_ERROR_READPRNG,
      CRYPT_INVALID_CIPHER, CRYPT_INVALID_HASH, CRYPT_INVALID_PRNG,
      CRYPT_MEM, CRYPT_PK_TYPE_MISMATCH, CRYPT_PK_NOT_PRIVATE,
      CRYPT_INVALID_ARG, CRYPT_FILE_NOTFOUND, CRYPT_PK_INVALID_TYPE,
      CRYPT_PK_INVALID_SYSTEM, CRYPT_PK_DUP, CRYPT_PK_NOT_FOUND,
      CRYPT_PK_INVALID_SIZE, CRYPT_INVALID_PRIME_SIZE,
      CRYPT_PK_INVALID_PADDING, CRYPT_HASH_OVERFLOW

    LtcExtraConst = enum
      LTC_FORTUNA_POOLS = 32

  doAssert isCryptOk             == CRYPT_OK.ord
  doAssert isCryptInvalidArg     == CRYPT_INVALID_ARG.ord
  doAssert isCryptHashOverflow   == CRYPT_HASH_OVERFLOW.ord
  doAssert isCryptBufferOverflow == CRYPT_BUFFER_OVERFLOW.ord
  doAssert ltcFrtaPools          == LTC_FORTUNA_POOLS.ord

  proc ltcConst(n: cint): cstring {.cdecl, importc: "ltc_const".}

  block: # check/verify internal constants
    for sym in LtcConst.items:
      var s = sym.ord.cint.ltcConst
      when not defined(check_run):
        echo ">>> ", $sym, "=", sym.ord
        #echo ">>> ", $sym, " >>> ", s
      doAssert s == $sym

  block: # check/verify extra constants
    echo ""
    for sym in LtcExtraConst.items:
      if ($sym)[0].isDigit: # e.g. "33 (invalid data!)"
        continue
      var s = (sym.ord or 0x40000000).cint.ltcConst
      when not defined(check_run):
        echo ">>> ", $sym, "=", sym.ord
        #echo ">>> ", $sym, " >>> ", s
      doAssert s == $sym

#  when not defined(check_run):
#    echo "*** not yet"

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
