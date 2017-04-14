# -*- nim -*-
#
# $Id: cf6af692de7f642037c803a7f4dbd713dfb2d5b5 $
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

import
  spmx/spmx

# ----------------------------------------------------------------------------
# Interface xoroshiro128plus
# ----------------------------------------------------------------------------

{.compile: "xoroshiro128plus.c".}
proc xoroSet128next*(): culonglong {.cdecl, importc: "xoro128next".}
proc xoroSet128jump*()             {.cdecl, importc: "xoro128jump".}

{.compile: "xoro128seeder.c".}
proc xoroSet128seed(a, b: culonglong) {.cdecl, importc: "set_xoro128seed".}
proc xoroGet128seed(): ptr array[2,culonglong] {.cdecl, importc: "get_xoro128seed".}

# ----------------------------------------------------------------------------
# Public functions
# ----------------------------------------------------------------------------

import strutils

proc getX128Seed*(): (int64, int64) =
  ## extract state of PRNG (can be used to stash/resume)
  var s = xoroGet128seed()
  result[0] = s[0].int64
  result[1] = s[1].int64

proc setX128Seed*(a, b: int64) =
  ## The seeder must not be everywhere zero, so better
  ## use the single argument version.
  xoroSet128Seed a.culonglong, b.culonglong

proc setX128Seed*(seed: int64) =
  spmx64Seed(seed)
  var
    a = spmx64next().culonglong
    b = spmx64next().culonglong
  xoroSet128Seed a.culonglong, b.culonglong

proc x128Next*(): int64 {.inline.} =
  xoroSet128next().int64

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:

  import strutils, sequtils

  block: # assert seeder exchange
    var
      a0 = 0x123456789
      a1 = 0x987654321
    setX128Seed(a0, a1)
    var b = getX128Seed()
    when not defined(check_run):
      discard
      echo ">>> ", a0, " >> ", b.repr
    doAssert a0 == b[0]
    doAssert a1 == b[1]

  block: # apply
    spmx64Seed(0x123456789)
    var
      a0 = spmx64next()
      a1 = spmx64next()
    setX128Seed(a0, a1)
    var b = getX128Seed()
    when not defined(check_run):
      discard
      #echo ">>> ", a0, " >> ", a1, " >> (", b[0], ", ", b[1], ")"
    doAssert a0 == b[0]
    doAssert a1 == b[1]
    for n in 0..10:
      var w = x128Next()
      when not defined(check_run):
        echo ">> ", w.toHex

#  when not defined(check_run):
#    echo "*** ", tes2Tail

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
