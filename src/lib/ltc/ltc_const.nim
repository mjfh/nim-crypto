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

# ----------------------------------------------------------------------------
# Public
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

  import
    misc / [prjcfg]

  {.passC: " -I " & "headers".nimSrcDirname.}

  var
    varCryptOk {.
      importc: "CRYPT_OK",              header: "tomcrypt.h".}: int
    varCryptBufferOverflow {.
      importc: "CRYPT_BUFFER_OVERFLOW", header: "tomcrypt.h".}: int
    varCryptInvalidArg {.
      importc: "CRYPT_INVALID_ARG",     header: "tomcrypt.h".}: int
    varCryptHashOverflow {.
      importc: "CRYPT_HASH_OVERFLOW",   header: "tomcrypt.h".}: int
    varFrtaPools {.
      importc: "LTC_FORTUNA_POOLS",     header: "tomcrypt.h".}: int

  doAssert isCryptOk             == varCryptOk
  doAssert isCryptInvalidArg     == varCryptInvalidArg
  doAssert isCryptHashOverflow   == varCryptHashOverflow
  doAssert isCryptBufferOverflow == varCryptBufferOverflow
  doAssert ltcFrtaPools          == varFrtaPools

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
