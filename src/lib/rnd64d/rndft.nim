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

## Random generator based Fortuna

import
  hashes, times, strutils, sequtils,
  ltc / [frta]

type
  RndFrta* = Frta

# ----------------------------------------------------------------------------
# Public functions
# ----------------------------------------------------------------------------

proc initRndFrta*(ctx: var RndFrta; seed1, seed2: int64) =
  ## Globally initialise Fortuna based random generator
  block fail:
    if not ctx.getFrta:
      break fail
    if not ctx.frtaAddEntropy(unsafeAddr seed1, seed1.sizeof):
      break fail
    if not ctx.frtaAddEntropy(unsafeAddr seed2, seed2.sizeof):
      break fail
    return
  quit "Fortuna initialisation error"

proc rndFrtaNext*(ctx: var RndFrta): int64 {.inline.} =
  discard ctx.readFrta(addr result, result.sizeof)

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:
  const
    ccInit = hash("wonderland")
  when not defined(check_run):
    echo ">>> ccInit=", ccInit.toHex

  block:
    var ctx: RndFrta
    ctx.initRndFrta(0,ccInit)
    for n in 0..3:
      var w = ctx.rndFrtaNext
      when not defined(check_run):
        echo ">>>> ", w.toHex
    when not defined(check_run):
      echo ""

  block:
    var ctx: RndFrta
    ctx.initRndFrta(0,hash(CompileTime & CompileDate & hostOS & hostCPU))
    for n in 0..3:
      var w = ctx.rndFrtaNext
      when not defined(check_run):
        echo ">>>> ", w.toHex

#  when not defined(check_run):
#    echo "*** not yet"

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
