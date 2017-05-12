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

const # to be verified in unit test
  salsaKeySize = @[128, 256]
  salsaIvSize  = @[64]

type
  SalsaIV*   = tuple[data: array[1,uint64]]
  SalsaHKey* = tuple[data: array[2,uint64]]        ## small key
  SalsaKey*  = tuple[data: array[4,uint64]]        ## recommended key
  SalsaCtx*  = tuple
    data: array[16,uint32]

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:

  import
    misc / [prjcfg]

  {.passC: " -I " & "private".nimSrcDirname.}

  var
    p: SalsaCtx
    a = cast[int](addr p)
    varSalsaCtxInput {.
      importc: "offsetof(ECRYPT_ctx, input)",
      header: "ecrypt-sync.h".}: int
    varSalsaSizeof {.
      importc: "sizeof(ECRYPT_ctx)",
      header: "ecrypt-sync.h".}: int
  doAssert varSalsaCtxInput == (cast[int](addr p.data) - a)
  doAssert varSalsaSizeof   == (p.sizeof)

  var
    varMaxKeySize {.
      importc: "ECRYPT_MAXKEYSIZE",
      header: "ecrypt-sync.h".}: int
    varKeySize0 {.
      importc: "ECRYPT_KEYSIZE(0)",
      header: "ecrypt-sync.h".}: int
    varKeySize1 {.
      importc: "ECRYPT_KEYSIZE(1)",
      header: "ecrypt-sync.h".}: int
    varKeySize2 {.
      importc: "ECRYPT_KEYSIZE(2)",
      header: "ecrypt-sync.h".}: int
    varMaxIvSize {.
      importc: "ECRYPT_MAXIVSIZE",
      header: "ecrypt-sync.h".}: int
    varIvSize0 {.
      importc: "ECRYPT_IVSIZE(0)",
      header: "ecrypt-sync.h".}: int
    varIvSize1 {.
      importc: "ECRYPT_IVSIZE(1)",
      header: "ecrypt-sync.h".}: int
    varIvSize2 {.
      importc: "ECRYPT_IVSIZE(2)",
      header: "ecrypt-sync.h".}: int
  doAssert varMaxKeySize == salsaKeySize[^1]
  doAssert varKeySize0   == salsaKeySize[0]
  doAssert varKeySize1   == salsaKeySize[^1]
  doAssert varMaxIvSize  == salsaIvSize[^1]
  doAssert varIvSize0    == salsaIvSize[0]
  doAssert varIvSize0    == salsaIvSize[^1]

  doAssert salsaKeySize[0] == 8 * SalsaHKey.sizeof
  doAssert salsaKeySize[1] == 8 * SalsaKey.sizeof
  doAssert salsaIvSize[0]  == 8 * SalsaIV.sizeof

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
