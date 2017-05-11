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
  ltc  / [ltc_const],
  misc / [prjcfg]

# ----------------------------------------------------------------------------
# SHA256 compiler
# ----------------------------------------------------------------------------

const
  stdCcFlgs = " -I " & "headers".nimSrcDirname

when isMainModule:
  const ccFlags = stdCcFlgs
else:
  const ccFlags = stdCcFlgs & " -DNO_LTC_TEST"

{.passC: ccFlags.}

{.compile: "sha256d/ltc_sha256.c"     .nimSrcDirname.}
{.compile: "crypt/ltc_crypt-argchk.c" .nimSrcDirname.}

# ----------------------------------------------------------------------------
# Interface ltc/sha256
# ----------------------------------------------------------------------------

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
# Debugging helper
# ----------------------------------------------------------------------------

proc dumpSha100State*(md: Sha100State; sep = " "): string =
  result = ""
  for n in 0..<md.state.len:
    if result.len != 0:
      result &= sep
    result &= md.state[n].BiggestInt.toHex(8).toLowerAscii

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
    HashState = tuple
      sha: Sha100State

  {.compile: "sha256d/ltc_sha256specs.c".nimSrcDirname.}
  proc sha100Test():         cint    {.cdecl, importc: "ltc_sha256_test".}
  proc zSha100Specs():       pointer {.cdecl, importc: "ltc_sha256_specs".}

  proc toSeq(a: Sha100Data): seq[int8] =
    result = newSeq[int8](a.len)
    for n in 0..<a.len:
      result[n] = a[n].int.toU8

  proc tSha100Specs(): seq[int] =
    result = newSeq[int](0)
    var
      p: HashState
      a = cast[int](addr p)
    result.add(cast[int](addr p.sha.length) - a)
    result.add(cast[int](addr p.sha.state)  - a)
    result.add(cast[int](addr p.sha.curlen) - a)
    result.add(cast[int](addr p.sha.buf)    - a)
    result.add(p.sha.sizeof)
    result.add(p.sizeof)
    result.add(0xffff)

  if true: # external self test
    var rc = sha100Test()
    #echo ">> ", rc
    doAssert isCryptOk == rc

  if true: # test state descriptor layout
    var
      a: array[7,cint]
      v = tSha100Specs()
    (addr a[0]).copyMem(zSha100Specs(), sizeof(a))
    var w = a.mapIt(int, it)
    when not defined(check_run):
      echo ">> desc: ", v
    # echo ">> ", v, " >> ", w
    doAssert v == w

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
        # echo ">>> ", h.dumpSha100State
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
