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

import
  os, sequtils, strutils, macros

# ----------------------------------------------------------------------------
# SHA256 compiler
# ----------------------------------------------------------------------------

template getCwd: string =
  instantiationInfo(-1, true).filename.parentDir

const
  cwd       = getCwd                               # starts with current ..
  D         = cwd[2 * (cwd[1] == ':').ord]         # .. DirSep, may differ ..
  srcIncDir = cwd & D & "headers"                  # .. from target DirSe
  srcSrcDir = cwd & D & "sha256d"
  srcExtDir = cwd & D & "crypt"
  stdCcFlgs = "-I " & srcIncDir

when isMainModule:
  const ccFlags = stdCcFlgs
else:
  const ccFlags = stdCcFlgs & " -DNO_LTC_TEST"

{.passC: ccFlags.}

{.compile: srcSrcDir & D & "ltc_sha256.c".}
{.compile: srcExtDir & D & "ltc_crypt-const.c".}
{.compile: srcExtDir & D & "ltc_crypt-argchk.c".}

# ----------------------------------------------------------------------------
# Interface ltc/sha256
# ----------------------------------------------------------------------------

const
  isCryptOk           =  0
  isCryptInvalidArg   = 16
  isCryptHashOverflow = 25

type
  Sha100Data* = array[32, uint8]
  Sha100State* = tuple
    length: uint64
    state:  array[8, uint32]
    curlen: uint32
    buf:    array[64, uint8]

proc ltc_sha256_init(md: ptr Sha100State): cint {.cdecl, importc.}
  ## Init hash descriptor.
  ##
  ## The function will return
  ##  * isCryptInvalidArg -- illegal null pointer argument
  ## or isCryptOk, otherwise

proc ltc_sha256_process(md: ptr Sha100State;
                        p: pointer; n: culong): cint {.cdecl, importc.}
  ## Process hash data.
  ##
  ## The function will return
  ##  * isCryptInvalidArg   -- illegal (eg. null pointer) argument
  ##  * isCryptHashOverflow -- very large or neg. n (counter size overflow)
  ## or isCryptOk, otherwise

proc ltc_sha256_done(md: ptr Sha100State; p: pointer): cint {.cdecl, importc.}
  ## Finalise hash data, p referes to a 32 byte data buffer.
  ##
  ## The function will return
  ##  * isCryptInvalidArg   -- illegal (eg. null pointer) argument
  ##  * isCryptHashOverflow -- very large n (counter size overflow)
  ## or isCryptOk, otherwise

# ----------------------------------------------------------------------------
# Public interface
# ----------------------------------------------------------------------------

proc getSha100*(md: var Sha100State) =
  ## Init sha-256 hash descriptor.
  discard ltc_sha256_init(addr md)

proc sha100Data*(md: var Sha100State; data: pointer; size: int) {.inline.} =
  ## Add hash data, size should be smaller than 2^30
  if ltc_sha256_process(addr md, data, size.culong) != 0:
    quit "sha100Data: arg error"

proc sha100Done*(md: var Sha100State; rc: ptr Sha100Data) {.inline.} =
  ## finalise hash
  if ltc_sha256_done(addr md, rc) != 0:
    quit "sha100Done: arg error"
  (addr md).zeroMem(md.sizeof)

proc sha100Done*(md: var Sha100State; rc: var Sha100Data) {.inline.} =
  ## finalise hash
  md.sha100Done(addr rc)

proc sha100Done*(md: var Sha100State): Sha100Data {.inline.} =
  ## finalise hash
  md.sha100Done(result)

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:
  type
    Sha100Const = enum
      CRYPT_OK = 0, CRYPT_ERROR, CRYPT_NOP, CRYPT_INVALID_KEYSIZE,
      CRYPT_INVALID_ROUNDS, CRYPT_FAIL_TESTVECTOR, CRYPT_BUFFER_OVERFLOW,
      CRYPT_INVALID_PACKET, CRYPT_INVALID_PRNGSIZE, CRYPT_ERROR_READPRNG,
      CRYPT_INVALID_CIPHER, CRYPT_INVALID_HASH, CRYPT_INVALID_PRNG,
      CRYPT_MEM, CRYPT_PK_TYPE_MISMATCH, CRYPT_PK_NOT_PRIVATE,
      CRYPT_INVALID_ARG, CRYPT_FILE_NOTFOUND, CRYPT_PK_INVALID_TYPE,
      CRYPT_PK_INVALID_SYSTEM, CRYPT_PK_DUP, CRYPT_PK_NOT_FOUND,
      CRYPT_PK_INVALID_SIZE, CRYPT_INVALID_PRIME_SIZE,
      CRYPT_PK_INVALID_PADDING, CRYPT_HASH_OVERFLOW

  doAssert isCryptOk           == CRYPT_OK.ord
  doAssert isCryptInvalidArg   == CRYPT_INVALID_ARG.ord
  doAssert isCryptHashOverflow == CRYPT_HASH_OVERFLOW.ord

  {.compile: srcSrcDir & D & "ltc_sha256specs.c".}
  proc sha100Const(n: cint): cstring {.cdecl, importc: "ltc_const".}
  proc sha100Test():         cint    {.cdecl, importc: "ltc_sha256_test".}
  proc zSha100Specs():       pointer {.cdecl, importc: "ltc_sha256_specs".}

  proc toSeq(a: Sha100Data): seq[int8] =
    result = newSeq[int8](a.len)
    for n in 0..<a.len:
      result[n] = a[n].int.toU8

  proc tSha100Specs(): seq[int] =
    result = newSeq[int](0)
    var
      p: Sha100State
      a = cast[int](addr p)
    result.add(cast[int](addr p.length) - a)
    result.add(cast[int](addr p.state)  - a)
    result.add(cast[int](addr p.curlen) - a)
    result.add(cast[int](addr p.buf)    - a)
    result.add(sizeof(p))
    result.add(0xffff)

  if true: # check/verify internal constants
    var n = 0
    while true:
      var s = sha100Const(n.cint)
      if s.isNil:
        break
      # echo ">>> ", $s, " >> ", $(n.Sha100Const)
      doAssert $s == $(n.Sha100Const)
      n.inc
    # echo ">> ", n, " >> ", Sha100Const.high.ord
    doAssert n == 1 + Sha100Const.high.ord

  if true: # external self test
    var n = sha100Test()
    #echo ">> ", n
    doAssert n.Sha100Const == CRYPT_OK

  if true: # test state descriptor layout
    var
      a: array[6,cint]
      v = tSha100Specs()
    (addr a[0]).copyMem(zSha100Specs(), sizeof(a))
    #echo ">> ", v, " >> ", a.mapIt(int, it)
    doAssert v == a.mapIt(int, it)

  if true: # test vectors
    const
      testVec = [
                 # http://en.wikipedia.org/wiki/SHA-2
                 ("",                           # w'pedia
                  "" & "e3b0c44298fc1c149afbf4c8996fb924" &
                       "27ae41e4649b934ca495991b7852b855"),

                 # http://www.di-mgt.com.au/sha_testvectors.html
                 ("abc",
                   "" & "ba7816bf8f01cfea414140de5dae2223" &
                        "b00361a396177a9cb410ff61f20015ad"),
                 ("abcdefghbcdefghicdefghijdefghijk" &
                  "efghijklfghijklmghijklmnhijklmno" &
                  "ijklmnopjklmnopqklmnopqrlmnopqrs" &
                  "mnopqrstnopqrstu",
                  "" & "cf5b16a778af8380036ce59e7b049237" &
                       "0b249b11e8f07a51afac45037afee9d1")]
    for n in 0..<testVec.len:
      block:
        var
          (sIn, sOut) = testVec[n]
          h: Sha100State
          v: Sha100Data
        h.getSha100
        h.sha100Data(addr sIn[0], sIn.len)
        h.sha100Done(v)
        var
          w = v.toSeq.mapIt(it.toHex(2).toLowerAscii).join
        when not defined(check_run) and false:
          echo ">>> ", n, " >> ", sIn
          echo ">>> ", sOut
          echo ">>> ", w
        doAssert w == sOut
      block:
        var
          (sIn, sOut) = testVec[n]
          h: Sha100State
        h.getSha100()
        h.sha100Data(addr sIn[0], sIn.len)
        var
          v = h.sha100Done
          w = v.toSeq.mapIt(it.toHex(2).toLowerAscii).join
        when not defined(check_run) and false:
          echo ">>> ", n, " >> ", sIn
          echo ">>> ", sOut
          echo ">>> ", w
        doAssert w == sOut

#  when not defined(check_run):
#    echo "*** not yet"

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
