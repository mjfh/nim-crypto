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
# Interface splitmix64
# ----------------------------------------------------------------------------

type
  Spmx64Seed = culonglong
  X64Seed* = int64
  
{.compile: "splitmix64.c".}
proc spmxSet64next*(): culonglong {.cdecl, importc: "spmx64next".}

{.compile: "spmx64seeder.c".}
proc spmxGetSeed*(): culonglong {.cdecl, importc: "get_spmx64seed".}
proc spmxSetSeed*(s: culonglong) {.cdecl, importc: "set_spmx64seed".}

# ----------------------------------------------------------------------------
# Public functions
# ----------------------------------------------------------------------------

proc spmx64Seed*(seed: int64) {.inline.} =
  spmxSetSeed seed.culonglong

proc spmx64next*(): int64 {.inline.} =
  spmxSet64next().int64
  
# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:
  import strutils

  block:
    spmx64Seed(0x123456789)
    var w = spmxGetSeed().int64
    when not defined(check_run):
      echo ">> ", w.toHex

  block:
    for n in 0..10:
      var w = spmx64next()
      when not defined(check_run):
        echo ">> ", w.toHex
  
#  when not defined(check_run):
#    echo "*** not yet"

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
