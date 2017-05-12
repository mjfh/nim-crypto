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

## Random generator based Xoro

import
  hashes, times, strutils, sequtils,
  xoro / [xoro]

# ----------------------------------------------------------------------------
# Public functions
# ----------------------------------------------------------------------------

proc initRndXo*(seed1, seed2: int64) =
  ## Globally initialise Xoro based random generator
  var h: Hash = 0
  h = h !& hash(seed1)
  h = h !& hash(seed2)
  setX128Seed(!$h)

proc rndXoNext*(): int64 {.inline.} =
  x128Next()

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:
  const
    ccInit = hash("blimey")
  when not defined(check_run):
    echo ">>> ccInit=", ccInit.toHex

  block:
    0.initRndXo(ccInit)
    for n in 0..3:
      var w = rndXoNext()
      when not defined(check_run):
        echo ">>>> ", w.toHex
    when not defined(check_run):
      echo ""

  block:
    0.initRndXo(hash(CompileTime & CompileDate & hostOS & hostCPU))
    for n in 0..3:
      var w = rndXoNext()
      when not defined(check_run):
        echo ">>>> ", w.toHex

#  when not defined(check_run):
#    echo "*** not yet"

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
