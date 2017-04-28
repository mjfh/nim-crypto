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

## Random generator based on Xoro, CacCha, and Fortuna to be activated at
## compile time.

import
  hashes, times, strutils, sequtils

# Set some text for static initialisation. This allows for random
# generator replay for Xoro or CacCha.
#const useFixedInitStr = "rubbish bin"

# activate some random generator (defailt is Fortuna)
type  RndGenType = enum FortunaRandom, XoroRandom, ChaChaRandom
#const rndGenType = ChaChaRandom


when not declared(rndGenType):
  const rndGenType = FortunaRandom


# check compile time dependent init string/seed
when not declared(useFixedInitStr):
  const ccInit = hash(CompileTime & CompileDate & hostOS & hostCPU)
else:
  const ccInit = hash(useFixedInitStr)

  # Fortuna will allways reseed differently => no warning needed
  when rndGenType != FortunaRandom:
    {.warning: "Using fixed init string '"&useFixedInitStr&"' for seeding".}


# Fortuna is considered safe by design (but check implementation)
when rndGenType != FortunaRandom:
  {.warning: $rndGenType & ": consider using Fortuna random generator".}

else: # but Fortuna is a bad choice for replay and debugging
  when not defined(release)  and
       not isMainModule      and
       declared(useFixedInitStr):
    {.warning: "FortunaRandom cannot be used for replay debugging".}

# ----------------------------------------------------------------------------
# Private functions
# ----------------------------------------------------------------------------

when rndGenType == ChaChaRandom:
  ##
  ## Activated random generator: ChaCha20
  ##
  import rnd64d/rndcc
  var ctx: RndCcCtx
  proc seedRandom64(seed: int64) {.inline.} =
    ctx.initRndCcCtx(seed.uint64, ccInit)
  proc nextRandom64(): int64 {.inline.} =
    ctx.rcdCcNext

when rndGenType == XoroRandom:
  ##
  ## Activated random generator: Xoro
  ##
  import rnd64d/rndxo
  proc seedRandom64(seed: int64) {.inline.} =
    initRndXo(seed, ccInit)
  proc nextRandom64(): int64 {.inline.} =
    rndXoNext()

when rndGenType == FortunaRandom:
  ##
  ## Activated random generator: Fortuna
  ##
  import rnd64d/rndft
  var ctx: RndFrta
  proc seedRandom64(seed: int64) {.inline.} =
    ctx.initRndFrta(seed, ccInit)
  proc nextRandom64(): int64 {.inline.} =
    ctx.rndFrtaNext

# initialise random generator
0.seedRandom64

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
