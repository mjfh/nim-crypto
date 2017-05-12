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
  ChaChaIV*   = tuple[data: array[ 1,uint64]] ## nonce, initialisation vector
  ChaChaHKey* = tuple[data: array[ 2,uint64]] ## small key
  ChaChaKey*  = tuple[data: array[ 4,uint64]] ## recommended key
  ChaChaBlk*  = tuple[data: array[64, uint8]] ## 64 byte data block
  ChaChaXBlk* = tuple[data: array[16,uint32]] ## data block (other format)
  ChaChaData* = ChaChaIV|ChaChaHKey|ChaChaKey|ChaChaBlk|ChaChaXBlk
  ChaChaCtx* = tuple                          ## descriptor, holds context
    schedule:  ChaChaBlk
    keystream: ChaChaBlk
    available: csize

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:

  import
    misc / [prjcfg]

  {.passC: " -I " & "private".nimSrcDirname.}

  var
    p: ChaChaCtx
    a = cast[int](addr p)
    varChaChaSchedule {.
      importc: "offsetof(chacha20_ctx, schedule)",
      header: "chacha20_simple.h".}: int
    varChaChaKeyStream {.
      importc: "offsetof(chacha20_ctx, keystream)",
      header: "chacha20_simple.h".}: int
    varChaChaAvailable {.
      importc: "offsetof(chacha20_ctx, available)",
      header: "chacha20_simple.h".}: int
    varChaChaCtxSizeof {.
      importc: "sizeof(chacha20_ctx)",
      header: "chacha20_simple.h".}: int
  doAssert varChaChaSchedule  == (cast[int](addr p.schedule)  - a)
  doAssert varChaChaKeyStream == (cast[int](addr p.keystream) - a)
  doAssert varChaChaAvailable == (cast[int](addr p.available) - a)
  doAssert varChaChaCtxSizeof == (sizeof(p))

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
