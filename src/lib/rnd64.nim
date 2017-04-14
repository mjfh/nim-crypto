# -*- nim -*-
#
# $Id: 2b3829a418cc6764e4ba2c1b004fc6e7d4a546ff $
#
# Copyright (c) 2017 Jordan Hrycaj <jordan@teddy-net.com>
# All rights reserved.
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
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

## Random generator based on XORO (similar to the NIM implementation) or
## on ChaCha20 depending on which one is activated internally.
##

import
  hashes, times, strutils, sequtils

const
  useChaChaRandom = true
  useFixedInitStr = ""          # set some text for static initialisation

# ----------------------------------------------------------------------------
# Private functions
# ----------------------------------------------------------------------------

when useChaChaRandom:
  import chacha/chacha
  ## Note:
  ##    This is the ChaCha20 based version.
  ##
else:
  import xoro/xoro
  ## Note:
  ##    This is the XORO based version.
  ##

## Unless deconfigured, this library will produce a different random
## sequence each time it is compiled.. This is achieved by the following
## strategy:
##
## Compile time setup:
##
##  * Create ccInit, a hashed compile time random (well sort of) string.
##
## Runtime initialisation:
##
##  * Initialise with random seed derived from ccInit
##
## Active re-seeding:
##
##  * Mangle ccInit into re-seeding value
##
when useFixedInitStr != "":
  {.warning: "Using fixed init string '" & useFixedInitStr & "' for seeding".}
  const ccInit = hash(useFixedInitStr)
else:
  {.warning: "rnd64: replace random generator soon".}
  const ccInit = hash(CompileTime & CompileDate & hostOS & hostCPU)

when useChaChaRandom:
  type
    CcMask = array[5,uint64]

  proc mkCMsk(bitMap: int64): CcMask =
    for inx in 0..3:
      for nibble in 0..15:
        var
          bit = inx * 16 + nibble
          msk = 1 shl bit
          val = (bitMap and msk) shr bit
        if val != 0:
          result[1 + inx] = result[1 + inx] or (15u64 shl (4 * bit))

  # Create ccMask, a 5x64 bit seed mask array derived from ccInit
  const
    ccMask = mkCMsk(ccInit)

  proc mkCCtx(x: var ChaChaCtx; seed: uint64) {.inline.} =
    var
      k: ChaChaKey = (data: [seed xor ccMask[0],
                             seed xor ccMask[1],
                             seed xor ccMask[2],
                             seed xor ccMask[3]])
      n: ChaChaIV  = (data: [seed xor ccMask[4]])
    x.getChaCha(addr k, addr n)

  # initialised random generator state data area
  var cCtx: ChaChaCtx
  cCtx.mkCCtx(0u64)

  # random method wrappers to be used in public functions
  proc seedRandom64(seed: int64) {.inline.} =
    cCtx.mkCCtx(seed.uint64)

  proc nextRandom64(): int64 {.inline.} =
    cCtx.chachaKeyStream(addr result, 8)

else:

  # random method wrappers to be used in public functions
  proc seedRandom64(seed: int64) {.inline.} =
    var h: Hash = 0
    h = h !& hash(seed)
    h = h !& hash(ccInit)
    setX128Seed(!$h)

  proc nextRandom64(): int64 {.inline.} =
    x128Next()

  # default random generator initialisation
  seedRandom64(0)

# ----------------------------------------------------------------------------
# Public functions
# ----------------------------------------------------------------------------

proc rnd64init*(seeds: varargs[string,`$`]) =
  ## seed random generator
  var h: Hash = 0
  if seeds.len == 0:
    h = h !& hash($epochTime())
  for w in seeds:
    h = h !& hash(w)
  seedRandom64(!$h)


proc rnd64Next*(): int64 {.inline.} =
  ## get next 64 bit random integer
  nextRandom64()


#proc rndIntNext*(): int {.inline.} =
#  ## get next random integer
#  when int.high < int64.high:
#    nextRandom64().toU32.int
#  else:
#    nextRandom64().int


iterator rnd8items*(num: int): (int, int8) {.inline.} =
  ## walk over n random bytes
  var
    r: int64                     # cache
    p = -1                       # shift position
    n = 0
  while n < num:
    if p < 0:
      r = nextRandom64()         # cache
      p = 56                     # shift position
    var
      q = (r shr p) and 255      # result in last byte
    yield (n, q.int.toU8)
    p.dec(8)
    n.inc

iterator rnd16items*(num: int): (int, int16) {.inline.} =
  ## walk over n random bytes
  var
    r: int64                     # cache
    p = -1                       # shift position
    n = 0
  while n < num:
    if p < 0:
      r = nextRandom64()         # cache
      p = 48                     # shift position
    var q = (r shr p) and 0xffff # result in last word
    yield (n, q.int.toU16)
    p.dec(16)
    n.inc

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:

  when not defined(check_run):
    when int.sizeof == int64.sizeof:
      echo "*** 64 bit architecture"
    else:
      echo "*** 32 bit architecture"

  when not defined(check_run):
    echo ">>> ccInit=", ccInit.toHex

  when useChaChaRandom:
    var pfx = ">>> ccMask="
    for n in 0..4:
      when not defined(check_run):
        echo pfx, ccMask[n].int64.toHex(16).toLowerAscii.replace("0","-")
      pfx = " ".repeat(pfx.len-1) & "|"

  rnd64init()

  for n in 0..3:
    var w = rnd64next()
    when not defined(check_run):
      echo ">>>> ", w.toHex

  for n, w in rnd8items(11):
    discard
    when not defined(check_run):
      echo ">> (", n, ", ", w.toHex, ")"

#  when not defined(check_run):
#    echo "*** not yet"

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
