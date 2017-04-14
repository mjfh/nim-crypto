# -*- nim -*-
#
# $Id: 4232a3d4c26a734b9ad781f30daeea79a301df35 $
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
  os, sequtils, endians

template getCwd: string =
  instantiationInfo(-1, true).filename.parentDir

const
  cwd       = getCwd                            # starts with current ..
  D         = cwd[2 * (cwd[1] == ':').ord]      # .. DirSep, may differ ..
  slsSrcDir = cwd & D & "private"               # .. from target DirSep
  slsHeader = slsSrcDir & D & "ecrypt-sync.h"

{.passC: "-I " & slsSrcDir.}
{.compile: slsSrcDir & D & "salsa20.c".}

# ----------------------------------------------------------------------------
# Interface salsa20
# ----------------------------------------------------------------------------

type
  SalsaIV*   = tuple[data: array[1,uint64]]
  SalsaHKey* = tuple[data: array[2,uint64]]        ## small key
  SalsaKey*  = tuple[data: array[4,uint64]]        ## recommended key
  SalsaCtx*  = tuple
    data: array[16,uint32]

  SSKeyBuf[K: SalsaKey|SalsaHKey] = tuple
    buf: K
    nnn: SalsaIV

# Select keysize and ivsize from the set of supported values
proc salsa20_keysetup(x: ptr SalsaCtx; k: pointer; kbits, ignored: uint32)
  {.cdecl, header: slsHeader, importc: "salsa20_keysetup".}

# After having called salsa20_keysetup(), the user is allowed to call
# salsa20_ivsetup() different times in order to encrypt/decrypt different
# messages with the same key but different IV's.
proc salsa20_ivsetup(x: ptr SalsaCtx; iv: pointer)
  {.cdecl, header: slsHeader, importc.}

# Example:
#   salsa20_keysetup()
#   salsa20_ivsetup()
#   salsa20_encrypt_bytes()
#
# Parameters:
#   x -- context
#   u -- input data block pointer
#   w -- output data block pointer
#   n -- data block length
#
proc salsa20_anycrypt_bytes(x: ptr SalsaCtx; u, w: pointer; n: uint32)
  {.cdecl, header: slsHeader, importc.}

# ----------------------------------------------------------------------------
# Private helper
# ----------------------------------------------------------------------------

proc normalise[K](b: var SSKeyBuf[K];
                  key: ptr K; nce: ptr SalsaIV) {.inline.} =
  b = (buf: key[], nnn: nce[])

  for n in 0..<key.data.len:                             # to abstract from
    (addr b.buf.data[n]).bigEndian64(addr b.buf.data[n]) # endianess

  (addr b.nnn.data[0]).bigEndian64(addr b.nnn.data[0])

# ----------------------------------------------------------------------------
# Public functions
# ----------------------------------------------------------------------------

proc getSalsa*[K: SalsaKey|SalsaHKey](x: var SalsaCtx;
                                      key: ptr K; nonce: ptr SalsaIV) =
  var b: SSKeyBuf[K]
  b.normalise(key, nonce)
  salsa20_keysetup(addr x, addr b.buf, (8 * b.buf.sizeof).uint32, 0)
  salsa20_ivsetup( addr x, addr b.nnn)
  (addr b).zeroMem(b.sizeof)

proc salsaAnyCrypt*(x: var SalsaCtx; pOut, pIn: pointer; n: int) {.inline.} =
  # in/out reversed (!)
  salsa20_anycrypt_bytes(addr x, pIn, pOut, n.uint32)

proc salsaKeyStream*(x: var SalsaCtx; p: pointer; size: int) {.inline.} =
  p.zeroMem(size)
  salsa20_anycrypt_bytes(addr x, p, p, size.uint32)

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:
  import strutils, sequtils

  when not defined(check_run):
    when int.sizeof == int64.sizeof:
      echo "*** 64 bit architecture"
    else:
      echo "*** <= 32 bit architecture"

  block: # Verify structures
    {.compile: "salsa20specs.c".}
    proc xSalsaSpecs(): cstring {.cdecl, importc: "salsa20_specs".}
    proc tSalsaSpecs(): seq[int] =
      result = newSeq[int](0)
      var
        p: SalsaCtx
        a = cast[int](addr p)
      result.add(cast[int](addr p.data) - a)
      result.add(sizeof(p))
    var
      u = xSalsaSpecs().mapIt(int, it.ord and 127)
      v = tSalsaSpecs()
    when not defined(check_run):
      discard
      #echo ">>> ", u, " >> ", v
    doAssert u == v

  block:
    # Supported key and IV sizes. A user can enumerate the supported sizes by
    # running the following code:
    #
    # var n = 0
    # while get_salsa20_keysize(n) <= get_salsa20_maxkeysize():
    #   var keysize = get_salsa20_keysize(n)
    #   n.inc
    #   ...
    #
    # All sizes are in bits.
    #
    {.compile: "salsa20-const.c".}
    proc get_salsa20_maxkeysize():     cint {.cdecl, importc.}
    proc get_salsa20_keysize(n: cint): cint {.cdecl, importc.}
    proc get_salsa20_maxivsize():      cint {.cdecl, importc.}
    proc get_salsa20_ivsize(n: cint):  cint {.cdecl, importc.}
    var
      kySz = newSeq[int](0)
      ivSz = newSeq[int](0)
      n = 0
    while get_salsa20_keysize(n.cint) <= get_salsa20_maxkeysize():
      kySz.add(get_salsa20_keysize(n.cint).int)
      n.inc
    n = 0
    while get_salsa20_ivsize(n.cint) <= get_salsa20_maxivsize():
      ivSz.add(get_salsa20_ivsize(n.cint).int)
      n.inc
    when not defined(check_run):
      discard
      #echo ">>> ", kySz, " >> ", ivSz
    doAssert kySz == @[8 * SalsaHKey.sizeof, 8 * SalsaKey.sizeof]
    doAssert ivSz == @[8 * SalsaIv.sizeof]

  # ----

  proc getKeyStmStr(ctx: var SalsaCtx; oldPos, newPos: int): (int, string) =
    var
      buf: array[64, int8]
      skp = newPos - oldPos
    while 63 < skp:
      ctx.salsaKeyStream(addr buf, buf.len)
      skp -= buf.len
    if 0 < skp:
      ctx.salsaKeyStream(addr buf, skp)
    ctx.salsaKeyStream(addr buf, buf.len)
    result = (newPos +  buf.len, buf.mapIt(it.toHex(2)).join)

  proc newSalsa(key: seq[uint64]; nonce: uint64): SalsaCtx =
    var iv: SalsaIV = (data: [nonce])
    if key.len == 2:
      var ky: SalsaHKey = (data: [key[0], key[1]])
      result.getSalsa(addr ky, addr iv)
    else:
      var ky: SalsaKey = (data: [key[0], key[1], key[2], key[3]])
      result.getSalsa(addr ky, addr iv)


  block: # test vectors, try command: make -C private/info tv
    var
      testVect = [
        ("Set 1, vector# 0",
         @[0x8000000000000000u64,
           0x0000000000000000u64],                    # key
         @[0x0000000000000000u64],                    # iv
         @[(0,   "4DFA5E481DA23EA09A31022050859936" & # stream@pos
                 "DA52FCEE218005164F267CB65F5CFD7F" &
                 "2B4F97E0FF16924A52DF269515110A07" &
                 "F9E460BC65EF95DA58F740B7D1DBB0AA"),
           (192, "DA9C1581F429E0A00F7D67E23B730676" &
                 "783B262E8EB43A25F55FB90B3E753AEF" &
                 "8C6713EC66C51881111593CCB3E8CB8F" &
                 "8DE124080501EEEB389C4BCB6977CF95"),
           (448, "B375703739DACED4DD4059FD71C3C47F" &
                 "C2F9939670FAD4A46066ADCC6A564578" &
                 "3308B90FFB72BE04A6B147CBE38CC0C3" &
                 "B9267C296A92A7C69873F9F263BE9703")]),

        ("Set 1, vector# 9",
         @[0x0040000000000000u64,
           0x0000000000000000u64],
         @[0x0000000000000000u64],
         @[(0,   "0471076057830FB99202291177FBFE5D" &
                 "38C888944DF8917CAB82788B91B53D1C" &
                 "FB06D07A304B18BB763F888A61BB6B75" &
                 "5CD58BEC9C4CFB7569CB91862E79C459"),
           (448, "AB3216F1216379EFD5EC589510B8FD35" &
                 "014D0AA0B613040BAE63ECAB90A9AF79" &
                 "661F8DA2F853A5204B0F8E72E9D9EB4D" &
                 "BA5A4690E73A4D25F61EE7295215140C")]),

        ("Set 3, vector#135",
         @[0x8788898A8B8C8D8Eu64,
           0x8F90919293949596u64,
           0x9798999A9B9C9D9Eu64,
           0x9FA0A1A2A3A4A5A6u64],
         @[0x0000000000000000u64],
         @[(0,   "EE17A6C5E4275B77E5CE6B0549B556A6" &
                 "C3B98B508CC370E5FA9C4EA928F7B516" &
                 "D8C481B89E3B6BE41F964EE23F226A97" &
                 "E13F0B1D7F3C3FBBFF2E49A9A9B2A87F"),
           (448, "DA438732BA03CBB9AFFF4B796A0B4482" &
                 "EA5880D7C3B02E2BE135B81D63DF351E" &
                 "EECEFA571731184CD5CB7EEA0A1D1626" &
                 "83BA706373017EE078B8068B14953FBF")])]

    for nTest in 0..<testVect.len:
      var
        (tInfo, tKey, tNonce, tSample) = testVect[nTest]
      when not defined(check_run):
        discard
        echo "*** Test Vector ", tInfo
      var
        ctx = tKey.newSalsa(tNonce[0])
        pos = 0
      for n in 0..<tSample.len:
        var
          test = tSample[n]
          kst: string
        (pos, kst) = ctx.getKeyStmStr(pos, test[0])
        when not defined(check_run):
          discard
          #echo ">>> pos=", pos
          #echo ">>> kst=", kst
          #echo ">>> tst=", test[1]
        doAssert kst == test[1]

#  when not defined(check_run):
#    echo "*** not yet"

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
