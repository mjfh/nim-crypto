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
# Ackn (C-sources):
#   Copyright (C) 2014 insane coder
#   insanecoding.blogspot.com/, chacha20.insanecoding.org
#

##
## This chacha20 library interface wrappes the code from Insane Coder, see
## http://insanecoding.blogspot.com/ or http://chacha20.insanecoding.org
##
## Ackn:
##   ChaCha20 is a stream cipher created by Daniel Bernstein, see
##   http://cr.yp.to/chacha.html. This implementation focuses on simplicity
##   and correctness. Test vectors with a battery of unit tests are included.

import
  endians,
  misc / [prjcfg]

# ----------------------------------------------------------------------------
# ChaCha compiler
# ----------------------------------------------------------------------------

const
  chaHeader = "private/chacha20_simple.h".nimSrcDirname
  chaCflags = "-I " & "private".nimSrcDirname

{.passC: chaCflags.}
{.compile: "private/chacha20_simple.c".nimSrcDirname.}

type
  ChaChaIV*   = tuple[data: array[ 1,uint64]] ## nonce, initialisation vector
  ChaChaHKey* = tuple[data: array[ 2,uint64]] ## small key
  ChaChaKey*  = tuple[data: array[ 4,uint64]] ## recommended key
  ChaChaBlk*  = tuple[data: array[64, uint8]] ## 64 byte data block
  ChaChaXBlk* = tuple[data: array[16,uint32]] ## data block (other format)
  ChaChaData* = ChaChaIV|ChaChaHKey|ChaChaKey|ChaChaBlk|ChaChaXBlk
  ChaChaCtx* = tuple                          ## descriptor, holds context
    schedule:  ChaChaBlk
    keystream: ChaChaBlk
    available: csize

  CCKeyBuf[K: ChaChaHKey|ChaChaKey] = tuple
    buf: K
    nnn: ChaChaIV

# ----------------------------------------------------------------------------
# Debugging helper
# ----------------------------------------------------------------------------

proc rawPp(p: pointer; n: int; sep: string): string =
  var buf = newString(n)
  (addr buf[0]).copyMem(p, n)
  buf.mapIt(it.ord.toHex(2).toLowerAscii).join(sep)

proc pp(w: ChaChaData; sep=" "): string =
  ## Pretty print ChaCha block, key etc.
  var u = w
  (addr u).rawPp(u.sizeof, sep)

proc pp(w: ChaChaCtx; delim = ""; sep = ""): string =
  ## Pretty print ChaCha state object
  ("{schedule  = {" &  w.schedule.pp( sep) & "}" & delim &
   " keystream = {" &  w.keystream.pp(sep) & "}" & delim &
   " available = "  & $w.available         & "}")

proc fromHexSeq(buf: seq[int8]; sep = " "): string =
  ## dump an array or a data sequence as hex string
  buf.mapIt(it.toHex(2).toLowerAscii).join(sep)

proc toHexSeq(s: string): seq[int8] =
  ## Converts a hex string stream to a byte sequence, it raises an
  ## exception if the hex string stream is incorrect.
  result = newSeq[int8](s.len div 2)
  for n in 0..<result.len:
    result[n] = s[2*n..2*n+1].parseHexInt.toU8
  doAssert s == result.mapIt(it.toHex(2).toLowerAscii).join

# ----------------------------------------------------------------------------
# Interface chacha20
# ----------------------------------------------------------------------------

# Initialize a ChaCha20Ctx, must be called before all other functions
#
#   x -- context
#   k -- input key
#   n -- input key length in bytes
#   u -- nonce
#
proc chacha20Setup(x: ptr ChaChaCtx; k: pointer; n: csize; u: ptr ChaChaIV)
  {.cdecl, header: chaHeader, importc: "chacha20_setup".}

# Set internal counter to process a particular block number.
#
#   x -- context
#   n -- block counter number
#
proc chacha20CounterSet(x: ptr ChaChaCtx; w: clonglong)
  {.cdecl, header: chaHeader, importc: "chacha20_counter_set".}

# Raw keystream for current block. Counter is incremented upon use.
#
#   x -- context
#   w -- output data block pointer
#
proc chacha20Block(x: ptr ChaChaCtx; w: ptr ChaChaXBlk)
  {.cdecl, header: chaHeader, importc: "chacha20_block".}

# En/decrypt an arbitrary amount of plaintext, call continuously as needed
#
#   x -- context
#   u -- input data block pointer
#   w -- output data block pointer
#   n -- data block length
#
proc chacha20AnyCrypt(x: ptr ChaChaCtx; u, w: pointer; n: csize)
 {.cdecl, header: chaHeader, importc: "chacha20_encrypt".}

# ----------------------------------------------------------------------------
# Private helper
# ----------------------------------------------------------------------------

proc normalise[K](b: var CCKeyBuf[K];
                  key: ptr K; nce: ptr ChaChaIV) {.inline.} =
  b = (buf: key[], nnn: nce[])

  for n in 0..<key.data.len:                             # to abstract from
    (addr b.buf.data[n]).bigEndian64(addr b.buf.data[n]) # endianess

  (addr b.nnn.data[0]).bigEndian64(addr b.nnn.data[0])

  #echo ">>>   key ", b.buf.pp(""), " >> ", key[].pp
  #echo ">>> nonce ", b.nnn.pp(""), " >> ", nce[].pp

# ----------------------------------------------------------------------------
# Public functions
# ----------------------------------------------------------------------------

proc getChaCha*[K: ChaChaKey|ChaChaHKey](x: var ChaChaCtx;
                                         key: ptr K; nonce: ptr ChaChaIV) =
  ## Initialize chacha20, must be called before all other functions
  var b: CCKeyBuf[K]
  b.normalise(key, nonce)
  chacha20Setup(addr x, addr b.buf, key[].sizeof.csize, addr b.nnn)
  (addr b).zeroMem(b.sizeof)

proc chachaBlockSeek*(x: var ChaChaCtx; n: int|uint|uint64) {.inline.} =
  ## Set internal counter to process a particular ChaChaBlk block number.
  chacha20CounterSet(addr x, n.clonglong)


proc chachaBlock*(x: var ChaChaCtx; pOut: ptr ChaChaBlk) {.inline.} =
  ## Raw keystream for the current block.
  chacha20Block(addr x, cast[ptr ChaChaXBlk](pOut))


proc chachaAnyCrypt*(x: var ChaChaCtx;
                     pOut, pIn: pointer; size: int) {.inline.} =
  ## En/decrypt an arbitrary amount of plaintext, repeat as needed.
  ##
  ## Allowed mode of operations:
  ## * chachaBlockSeek()
  ## * chachaBlock()
  ## * chachaBlock()
  ## * chachaAnyCrypt()/chachaKeyStream()
  ## * . . .
  ## but not
  ## * chachaBlock()
  ## * chachaAnyCrypt()/chachaKeyStream()
  ## * chachaBlock()
  ##
  chacha20AnyCrypt(addr x, pIn, pOut, size.csize) # in/out reversed (!)


proc chachaKeyStream*(x: var ChaChaCtx; p: pointer; size: int) {.inline.} =
  ## Generates chacha20 key stream, i.e chachaAnyCrypt(x,p,p,size) where the
  ## data area p[] is initialised to zero.
  p.zeroMem(size)
  chacha20AnyCrypt(addr x, p, p, size.csize)

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:

  if true: # Verify structures
    {.compile: "chacha20specs.c".nimSrcDirname.}
    proc xChaChaSpecs(): pointer {.cdecl, importc: "chacha20_specs".}
    proc tChaChaSpecs(): seq[int] =
      result = newSeq[int](0)
      var
        p: ChaChaCtx
        a = cast[int](addr p)
      result.add(cast[int](addr p.schedule)  - a)
      result.add(cast[int](addr p.keystream) - a)
      result.add(cast[int](addr p.available) - a)
      result.add(sizeof(p))
      result.add(0xffff)
    var
      a: array[5,cint]
      v = tChaChaSpecs()
    (addr a[0]).copyMem(xChaChaSpecs(), sizeof(a))
    when not defined(check_run):
      discard
      #echo "*** Ctx layout: ", $a.mapIt(int, it), " >> ", $v
    doAssert v == a.mapIt(int, it)

  if true: # Run external test
    {.passC: chaCflags & " -DNIMSRC_LOCAL".}
    {.compile: "private/chacha20_test.c".nimSrcDirname.}
    proc chacha20test(): cstring {.cdecl, importc: "chacha20_test".}
    var
      s   = $chacha20test()
      err =  s.splitLines.filterIt(it.find("Success") < 0 and it != "")
    when not defined(check_run):
      discard
      #echo "*** Report: ", s
      #echo "*** Errors: ", err.len, " >> ", err
    doAssert err.len == 0

  if true: # run external test (checks interface)
    var testVect = [
          #
          # //tools.ietf.org/html/draft-agl-tls-chacha20poly1305-04#section-7
          #
          # 7.  Test vectors
          #
          # The following blocks contain test vectors for ChaCha20.  The first
          # line contains the 256-bit key, the second the 64-bit nonce and the
          # last line contains a prefix of the resulting ChaCha20 key-stream.
          ("chacha20poly1305-04#section-7 #1",
           @[0x0000000000000000u64,               # key
             0x0000000000000000u64,
             0x0000000000000000u64,
             0x0000000000000000u64],
           [0x0000000000000000u64],               # iv/nonce
           "",                                    # plain
           "76b8e0ada0f13d90405d6ae55386bd28" &   # cipher
           "bdd219b8a08ded1aa836efcc8b770dc7" &
           "da41597c5157488d7724e03fb8d84a37" &
           "6a43b8f41518a11cc387b669b2ee6586",
           0),                                    #  counter, number
          ("chacha20poly1305-04#section-7 #2",
           @[0x0000000000000000u64,
             0x0000000000000000u64,
             0x0000000000000000u64,
             0x0000000000000001u64],
           [0x0000000000000000u64],
           "",
           "4540f05a9f1fb296d7736e7b208e3c96" &
           "eb4fe1834688d2604f450952ed432d41" &
           "bbe2a0b6ea7566d2a5d1e7e20d42af2c" &
           "53d792b1c43fea817e9ad275ae546963",
           0),
          ("chacha20poly1305-04#section-7 #3",
           @[0x0000000000000000u64,
             0x0000000000000000u64,
             0x0000000000000000u64,
             0x0000000000000000u64],
           [0x0000000000000001u64],
           "",
           "de9cba7bf3d69ef5e786dc63973f653a" &
           "0b49e015adbff7134fcb7df137821031" &
           "e85a050278a7084527214f73efc7fa5b" &
           "5277062eb7a0433e445f41e3",
           0),
          ("chacha20poly1305-04#section-7 #4",
           @[0x0000000000000000u64,
             0x0000000000000000u64,
             0x0000000000000000u64,
             0x0000000000000000u64],
           [0x0100000000000000u64],
           "",
           "ef3fdfd6c61578fbf5cf35bd3dd33b80" &
           "09631634d21e42ac33960bd138e50d32" &
           "111e4caf237ee53ca8ad6426194a8854" &
           "5ddc497a0b466e7d6bbdb0041b2f586b",
           0),

          ("last one from chacha20_test.c",
           @[0x1c9240a5eb55d38au64,
             0xf333888604f6b5f0u64,
             0x473917c1402b8009u64,
             0x9dca5cbc207075c0u64],
           [0x0000000000000002u64],
           "2754776173206272696c6c69672c2061" &   # plain
           "6e642074686520736c6974687920746f" &
           "7665730a446964206779726520616e64" &
           "2067696d626c6520696e207468652077" &
           "6162653a0a416c6c206d696d73792077" &
           "6572652074686520626f726f676f7665" &
           "732c0a416e6420746865206d6f6d6520" &
           "7261746873206f757467726162652e",

           "62e6347f95ed87a45ffae7426f27a1df" &   # cipher
           "5fb69110044c0d73118effa95b01e5cf" &
           "166d3df2d721caf9b21e5fb14c616871" &
           "fd84c54f9d65b283196c7fe4f60553eb" &
           "f39c6402c42234e32a356b3e764312a6" &
           "1a5532055716ead6962568f87d3f3f77" &
           "04c6a8d1bcd1bf4d50d6154b6da731b1" &
           "87b58dfd728afa36757a797ac188d1",
           42)]                                   # counter

    proc newChaCha(key: seq[uint64], nonce: uint64): ChaChaCtx =
      var iv: ChaChaIV = (data: [nonce])
      if key.len == 2:
        var ky: ChaChaHKey = (data: [key[0], key[1]])
        result.getChaCha(addr ky, addr iv)
      else:
        var ky: ChaChaKey = (data: [key[0], key[1], key[2], key[3]])
        result.getChaCha(addr ky, addr iv)

    for n in 0..<testVect.len:
      var
        (tInfo, tKey, tNonce, tPlain, tCipher, tCounter) = testVect[n]
      when not defined(check_run):
        echo ">>> ", tInfo
      block:
        var
          length = tCipher.len div 2
          ctx    = tKey.newChaCha(tNonce[0])
          outBuf = newSeq[int8](length)
          inBuf  = if tPlain.len == 0: outBuf else: tPlain.toHexSeq

        # whole block
        ctx.chachaBlockSeek(tCounter)
        ctx.chachaAnyCrypt(addr outBuf[0], addr inBuf[0], length)
        #echo ">>> ", outBuf.fromHexSeq(""), " >> ", tCipher
        doAssert outBuf.fromHexSeq("") == tCipher

        # encoding stream snippets
        for i in 1..length:
          (addr outBuf[0]).zeroMem(length)
          ctx.chachaBlockSeek(tCounter)
          for j in countUp(0, <length, step = i):
            var size = min(i, inBuf.len-j)
            ctx.chachaAnyCrypt(addr outBuf[j], addr  inBuf[j], size)
          doAssert outBuf.fromHexSeq("") == tCipher

#  when not defined(check_run):
#    echo "*** not yet"

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
