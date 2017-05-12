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

## Random generator based ChaCha20

import
  hashes, times, strutils, sequtils,
  chacha / [chacha]

type
  RndCcMsk = array[5,uint64]
  RndCcCtx* = ChaChaCtx

# ----------------------------------------------------------------------------
# Private helpers
# ----------------------------------------------------------------------------

proc initRndCcMsk(ccMsk: var RndCcMsk; bitMap: int64) {.inline.} =
  ## Derive a 5x64 bit seed mask array from bitMap
  for inx in 0..3:
    for nibble in 0..15:
      var
        bit = inx * 16 + nibble
        msk = 1 shl bit
        val = (bitMap and msk) shr bit
      if val != 0:
        ccMsk[1 + inx] = ccMsk[1 + inx] or (15u64 shl (4 * bit))

# ----------------------------------------------------------------------------
# Public functions
# ----------------------------------------------------------------------------

proc initRndCcCtx*(ctx: var RndCcCtx; seed: uint64; mask: int64) =
  ## Initialise ChaCha20 based random generator with:
  ## * seed -- a 64bit initialisation value
  ## * mask -- a 64bit value recipe how to extend seed to 256 bits
  var
    m: RndCcMsk
  m.initRndCcMsk(mask)
  var
    k: ChaChaKey = (data: [seed xor m[0],
                           seed xor m[1],
                           seed xor m[2],
                           seed xor m[3]])
    n: ChaChaIV  = (data: [seed xor m[4]])
  ctx.getChaCha(addr k, addr n)

proc rcdCcNext*(ctx: var RndCcCtx): int64 {.inline.} =
  ## Get next 64bit random value
  ctx.chachaKeyStream(addr result, 8)

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:
  const
    ccInit = hash("can you pronounce chuchichaeschtli?")
  when not defined(check_run):
    echo ">>> ccInit=", ccInit.toHex

  block:
    var
      pfx = ">>> ccMask="
      msk: RndCcMsk
    msk.initRndCcMsk(ccInit)
    for n in 0..4:
      when not defined(check_run):
        echo pfx, msk[n].int64.toHex(16).toLowerAscii.replace("0","-")
      pfx = " ".repeat(pfx.len-1) & "|"

  block:
    var ctx: RndCcCtx
    ctx.initRndCcCtx(0u64,ccInit)
    for n in 0..3:
      var w = ctx.rcdCcNext()
      when not defined(check_run):
        echo ">>>> ", w.toHex
    when not defined(check_run):
      echo ""

  block:
    var ctx: RndCcCtx
    ctx.initRndCcCtx(0u64, hash(CompileTime & CompileDate & hostOS & hostCPU))
    for n in 0..3:
      var w = ctx.rcdCcNext()
      when not defined(check_run):
        echo ">>>> ", w.toHex

#  when not defined(check_run):
#    echo "*** not yet"

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
