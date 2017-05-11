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

type
  RijndaelKey* = tuple
    eK: array[60, uint32]   # ulong32 eK[60]
    dK: array[60, uint32]   # ulong32 dK[60];
    nR: cint

  Aes80Array* = array[16,uint8]
  Aes80Data*  = Aes80Array | array[16,int8]

when cint.sizeof != int.sizeof:
  # occures on 32bit machines due to struct into union embedding
  type Aes80Key* = tuple[rndl: RijndaelKey, pad: cint]
else:
  type Aes80Key* = tuple[rndl: RijndaelKey] # symmetric encryption key

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:

  import
    misc / [prjcfg]

  {.passC: " -I " & "headers".nimSrcDirname.}

  var
    p: Aes80Key
    a = cast[int](addr p)
    varAes80RndlEk {.
      importc: "offsetof(symmetric_key, rijndael.eK)",
      header: "tomcrypt.h".}: int
    varAes80RndlDk {.
      importc: "offsetof(symmetric_key, rijndael.dK)",
      header: "tomcrypt.h".}: int
    varAes80RndlNr {.
      importc: "offsetof(symmetric_key, rijndael.Nr)",
      header: "tomcrypt.h".}: int
    varAes80RndlKeySizeof {.
      importc: "sizeof(struct rijndael_key)",
      header: "tomcrypt.h".}: int
    varAes80SymKeySizeof {.
      importc: "sizeof(symmetric_key)",
      header: "tomcrypt.h".}: int
  doAssert varAes80RndlEk        == (cast[int](addr p.rndl.eK) - a)
  doAssert varAes80RndlDk        == (cast[int](addr p.rndl.dK) - a)
  doAssert varAes80RndlNr        == (cast[int](addr p.rndl.nR) - a)
  doAssert varAes80RndlKeySizeof == (p.rndl.sizeof)
  doAssert varAes80SymKeySizeof  == (p.sizeof)

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
