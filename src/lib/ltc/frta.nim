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
  os, sequtils, strutils, macros, ltc / [aes80, ltc_const, sha100]

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

type
  FrtaPools = array[ltcFrtaPools,Sha100State]
  FrtaPrng* = tuple
    pool:   FrtaPools              # the pools
    sKey:   Aes80Key
    K:      array[32,int8]         # the current key
    IV:     array[16,int8]         # IV for CTR mode
    pIdx:   culong                 # current pool we will add to
    p0Len:  culong                 # length of 0'th pool
    wd:     culong
    resCnt: uint64                 # number of times we have reset

  FrtaEntropy* = array[32*ltcFrtaPools,int8]

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
  ##   outLen -- [in/out] Max size and resulting size of the state (sets
  ##                      outLen to desired size if too small)
  ##   ctx    -- [in/out] The PRNG to export
  ##
  ## Returns:
  ##   isCryptOk if successful

#proc fortuna_import(inPtr: pointer; inLen: culong;
#                    ctx: ptr FrtaPrng): cint {.cdecl, importc.}
#  ## Import a PRNG state
#  ##
#  ## Arguments:
#  ##  inPtr  --      [in] The PRNG state
#  ##  inLen  --      [in] Size of the state
#  ##   ctx    -- [in/out] The PRNG to import
#  ##
#  ## Returns:
#  ##   isCryptOk if successful

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

proc fromHexSeq(buf: seq[int8]; sep = " "): string =
  ## dump an array or a data sequence as hex string
  buf.mapIt(it.toHex(2).toLowerAscii).join(sep)

proc fromHexSeq(buf: FrtaEntropy; sep1 = "\n", sep2 = " "): string =
  var q = newSeq[int8](ltcFrtaPools)
  result = ""
  for n in 0..<32:
    for m in 0..<ltcFrtaPools:
      q[m] = buf[n*32 + m].int.toU8
    if result.len != 0:
      result &= sep1
    result &= q.fromHexSeq(sep2)

proc fromHexSeq(buf: FrtaPools; sep1 = "\n", sep2 = " "): string =
  result = ""
  for n in 0..<buf.len:
    if result.len != 0:
      result &= sep1
    result &= buf[n].dumpSha100State(sep2)

proc toHexSeq(s: string): seq[int8] =
  ## Converts a hex string stream to a byte sequence, it raises an
  ## exception if the hex string stream is incorrect.
  result = newSeq[int8](s.len div 2)
  for n in 0..<result.len:
    result[n] = s[2*n..2*n+1].parseHexInt.toU8
  doAssert s == result.mapIt(it.toHex(2).toLowerAscii).join

# ----------------------------------------------------------------------------
# Public interface
# ----------------------------------------------------------------------------

proc frtaAddEntropy*(x: var FrtaPrng;
                     p: pointer; pLen: int): bool {.inline.} =
  ## Add entropy to the Fortuna PRNG
  if 0 < pLen:
    var
      pStart = 0
      pPtr   = cast[ptr array[int.high,int8]](p)
    # need to pass 32byte chunks
    block fail:
      #echo ">>> pool=[", x.pool.fromHexSeq("\n"&" ".repeat(10))
      while pStart < pLen:
        var
          bPtr = addr pPtr[pStart]
          bSz  = min(32, pLen - pStart)
          rc   = fortuna_add_entropy(bPtr, bSz.cuint, addr x)
        # echo ">>> pStart=", pStart, " pLen=", pLen, " rc=", rc
        if isCryptOk != rc:
          break fail
        pStart.inc(32)
      # reached here when loop terminated ok
      result = true
      #echo ">>> pool=[", x.pool.fromHexSeq("\n"&" ".repeat(10))


# inspired by: libtomcrypt/src/prngs/rng_make_prng.c
proc getFrta*(x: var FrtaPrng; rndBits = 1024; callBack: proc() = nil): bool =
  ## Initialise Fortuna random PRNG
  var
    buf: array[256,int8]
  let
    bPtr = cast[pointer](addr buf[0])
    ctx  = addr x
    bLen = (2 * ((rndBits.clamp(64,1024) + 7) div 8)).culong

  assert 64 <= rndBits and rndBits <= 1024
  assert bLen <= buf.sizeof.culong

  block fail:
    if isCryptOk != ctx.fortuna_start:
      break fail
    if bLen != rng_get_bytes(bPtr, bLen, callBack):
      break fail
    if not x.frtaAddEntropy(addr buf, bLen.int):
      break fail
    if isCryptOk != ctx.fortuna_ready:
      break fail
    return true

  ctx.zeroMem(x.sizeof)


proc clearFrta*(x: var FrtaPrng) {.inline.} =
  (addr x).zeroMem(x.sizeof)


proc readFrta*(x: var FrtaPrng; buf: pointer; bufLen: int): int {.inline.} =
  ## Get random bytes from Fortune random PRNG,
  ## returns bufLen or 0 (if error)
  fortuna_read(buf, bufLen.culong, addr x)


proc frtaExport*(x: var FrtaPrng; buf: var FrtaEntropy): bool {.inline.} =
  var bLen = buf.sizeof.culong
  if isCryptOk == fortuna_export(addr buf, addr bLen, addr x) and
     bLen == buf.sizeof.culong:
    result = true
  else:
    (addr buf).zeroMem(buf.sizeof)

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:
  type
    PrngState = tuple
      frta: FrtaPrng

  block: # verify entropy export size
    var
      n: culong = 0
      x: FrtaPrng
      p  = ""
      rc = isCryptBufferOverflow
    doAssert rc == fortuna_export(addr p[0], addr n, addr x)
    when not defined(check_run):
      echo ">>> FrtaEntropy=", n, " expected=", FrtaEntropy.sizeof
    doAssert n.int == FrtaEntropy.sizeof

  {.compile: srcSrcDir & D & "ltc_fortunaspecs.c".}
  block: # verify Aes80Key descriptor layout in C and NIM
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
    var
      a: array[12,cint]
      v = tFrtaSpecs()
    (addr a[0]).copyMem(zFrtaSpecs(), sizeof(a))
    var w = a.mapIt(int, it)
    when not defined(check_run):
      echo ">>> desc: ", v
    # echo ">>> ", v, " >> ", w
    doAssert v == w

  block: # invoke self test in C code
    proc fortuna_test(): cint {.cdecl, importc.}
    # echo ">>> ", fortuna_test()
    doAssert isCryptOk == fortuna_test()

  block: # check import/export
    var
      prng: FrtaPrng
      exp, exq: FrtaEntropy
    doAssert true == prng.getFrta
    doAssert true == prng.frtaExport(exp)

    doAssert true == prng.frtaAddEntropy(addr exp, exp.sizeof)
    doAssert true == prng.frtaExport(exq)

    #echo ">>> entropy=[", exp.fromHexSeq("\n"&" ".repeat(13)), "]"
    #echo ">>> entropy=[", exq.fromHexSeq("\n"&" ".repeat(13)), "]"
    doAssert exp != exq

  block: # read random data
    var prng: FrtaPrng
    doAssert true == prng.getFrta

    var data = newSeq[int8](20)
    doAssert data.len == prng.readFrta(addr data[0], data.len)
    when not defined(check_run):
      echo ">>> ", data.fromHexSeq

#  when not defined(check_run):
#    echo "*** not yet"

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
