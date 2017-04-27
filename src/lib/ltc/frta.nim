# -*- nim -*-
#
# $Id$
#
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

import
  os, sequtils, strutils, macros,

  ltc / [sha100, aes80]

# ----------------------------------------------------------------------------
# FORTUNA compiler
# ----------------------------------------------------------------------------

template getCwd: string =
  instantiationInfo(-1, true).filename.parentDir

const
  cwd       = getCwd                               # starts with current ..
  D         = cwd[2 * (cwd[1] == ':').ord]         # .. DirSep, may differ ..
  srcIncDir = cwd & D & "headers"                  # .. from target DirSe
  srcSrcDir = cwd & D & "fortunad"
  stdCcFlgs = "-I " & srcIncDir

when isMainModule:
  const ccFlags = stdCcFlgs
else:
  const ccFlags = stdCcFlgs & " -DNO_LTC_TEST"

{.passC: ccFlags.}

{.compile: srcSrcDir & D & "ltc_fortuna.c".}
{.compile: srcSrcDir & D & "ltc_rng_get_bytes.c".}

# ----------------------------------------------------------------------------
# Interface ltc/fortuna
# ----------------------------------------------------------------------------

const
  isCryptOk    =   0
  ltcFrtaPools =  32

type
  FrtaPrng* = tuple
    pool:   array[ltcFrtaPools,Sha100State] # the pools
    sKey:   Aes80Key
    K:      array[32,int8]                  # the current key
    IV:     array[16,int8]                  # IV for CTR mode
    pIdx:   culong                          # current pool we will add to
    p0Len:  culong                          # length of 0'th pool
    wd:     culong
    resCnt: uint64                          # number of times we have reset

proc fortuna_start(ctx: ptr FrtaPrng): cint {.cdecl, importc.}
  ## Start the PRNG
  ##
  ## Arguments:
  ##   ctx    --    [out] The PRNG state to initialize
  ##
  ## Returns:
  ##   isCryptOk if successful

proc fortuna_add_entropy(inPtr: pointer; inLen: culong;
                         ctx: ptr FrtaPrng): cint {.cdecl, importc.}
  ## Add entropy to the PRNG state
  ##
  ## Arguments:
  ##   inPtr  --     [in] The data to add
  ##   inLen  --     [in] Length of the data to add
  ##   ctx    -- [in/out] PRNG state to update
  ##
  ## Returns:
  ##   isCryptOk if successful

proc fortuna_ready(ctx: ptr FrtaPrng): cint {.cdecl, importc.}
  ## Make the PRNG ready to read from
  ##
  ## Arguments:
  ##   ctx    -- [in/out] The PRNG to make active
  ##
  ## Returns:
  ##   isCryptOk if successful

proc fortuna_read(outPtr: pointer; outLen: culong;
                  ctx: ptr FrtaPrng): cint {.cdecl, importc.}
  ## Read from the PRNG
  ##
  ## Arguments:
  ##   outPtr --    [out] Destination
  ##   outLen --     [in] Length of output
  ##   ctx    -- [in/out] PRNG state to update
  ##
  ## Returns:
  ##   number of octets read

#proc fortuna_done(ctx: ptr FrtaPrng): cint {.cdecl, importc.}
#  ## Terminate the PRNG
#  ##
#  ## Arguments:
#  ##   ctx    -- [in/out] PRNG state to terminate
#  ##
#  ## Returns:
#  ##   isCryptOk if successful

proc fortuna_export(outPtr: pointer; outLen: ptr culong;
                    ctx: ptr FrtaPrng): cint {.cdecl, importc.}
  ## Export the PRNG state
  ##
  ## Arguments:
  ##   outPtr --    [out] Destination
  ##   outLen -- [in/out] Max size and resulting size of the state
  ##   ctx    -- [in/out] The PRNG to export
  ##
  ## Returns:
  ##   isCryptOk if successful

proc fortuna_import(inPtr: pointer; inLen: culong;
                    ctx: ptr FrtaPrng): cint {.cdecl, importc.}
  ## Import a PRNG state
  ##
  ## Arguments:
  ##  inPtr  --      [in] The PRNG state
  ##  inLen  --      [in] Size of the state
  ##   ctx    -- [in/out] The PRNG to import
  ##
  ## Returns:
  ##   isCryptOk if successful

proc rng_get_bytes(outPtr: pointer; outLen: culong;
                   cBck: proc()): culong {.cdecl, importc.}
  ## Read the system RNG
  ##
  ## Arguments:
  ##   outPtr --    [out] Destination
  ##   outLen --     [in] Length desired (octets)
  ##   cBck  --      [in] function to call when RNG is slow (can be nil).
  ##
  ## Returns:
  ##   number of octets read

# ----------------------------------------------------------------------------
# Debugging helper
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# Public interface
# ----------------------------------------------------------------------------

# inspired by: libtomcrypt/src/prngs/rng_make_prng.c
proc getFrta*(x: var FrtaPrng; rndBits = 1024; callBack: proc() = nil): bool =
  ## Initialise Fortune random PRNG
  var
    buf: array[256,int8]

  let
    bPtr = cast[pointer](addr buf[0])
    ctx  = addr x
    bLen = (2 * ((rndBits.clamp(64,1024) + 7) div 8)).culong

  assert 64 <= rndBits and rndBits <= 1024
  assert bLen <= buf.sizeof.culong

  block fail:
    if isCryptOk != fortuna_start(ctx):
      break fail
    if bLen != rng_get_bytes(bPtr, bLen, callBack):
      break fail
    if isCryptOk != fortuna_add_entropy(bPtr, bLen, ctx):
      break fail
    if isCryptOk != fortuna_ready(ctx):
      break fail
    return true

  ctx.zeroMem(x.sizeof)


proc clearFrta*(x: var FrtaPrng) {.inline.} =
  (addr x).zeroMem(x.sizeof)


proc readFrta*(x: var FrtaPrng;
               buf: pointer; bufLen: int): bool {.inline.} =
  ## Get random bytes from Fortune random PRNG
  if isCryptOk == fortuna_read(buf, bufLen.culong, addr x):
    result = true


proc suspendFrta*(x: var FrtaPrng;
                  buf: pointer; bufLen: var int): bool {.inline.} =
  var bLen = bufLen.culong
  if isCryptOk == fortuna_export(buf, addr bLen, addr x):
    bufLen = bLen.int
    result = true
  else:
    buf.zeroMem(bufLen)
    bufLen = 0


proc resumeFrta*(x: var FrtaPrng;
                 buf: pointer; bufLen: int): bool {.inline.} =
  if isCryptOk == fortuna_import(buf, bufLen.cuint, addr x):
    buf.zeroMem(bufLen)
    result = true

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:
  type
    PrngState = tuple
      frta: FrtaPrng

  # verify Aes80Key descriptor layout in C and NIM
  {.compile: srcSrcDir & D & "ltc_fortunaspecs.c".}
  proc zFrtaSpecs(): pointer {.cdecl, importc: "ltc_fortuna_specs".}
  proc tFrtaSpecs(): seq[int] =
    result = newSeq[int](0)
    var
      p: PrngState
      a = cast[int](addr p)
    result.add(cast[int](addr p.frta.pool)    - a)
    result.add(cast[int](addr p.frta.pool[1]) - a)
    result.add(cast[int](addr p.frta.sKey)    - a)
    result.add(cast[int](addr p.frta.K)       - a)
    result.add(cast[int](addr p.frta.IV)      - a)
    result.add(cast[int](addr p.frta.pIdx)    - a)
    result.add(cast[int](addr p.frta.p0Len)   - a)
    result.add(cast[int](addr p.frta.wd)      - a)
    result.add(cast[int](addr p.frta.resCnt)  - a)
    result.add(p.frta.sizeof)
    result.add(p.sizeof)
    result.add(0xffff)
    result.add(ltcFrtaPools)
  var
    a: array[13,cint]
    v = tFrtaSpecs()
  (addr a[0]).copyMem(zFrtaSpecs(), sizeof(a))
  var w = a.mapIt(int, it)
  when not defined(check_run):
    echo ">> desc: ", v
  # echo ">> ", v, " >> ", w
  doAssert v == w

  proc fortuna_test(): cint {.cdecl, importc.}

#  when not defined(check_run):
#    echo "*** not yet"

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
