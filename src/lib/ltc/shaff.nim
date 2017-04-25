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

# Additional CC compiler flags (see libtomcrypt/doc/crypt.pdf):
#
# ARGTYPE         This lets you control how the LTC_ARGCHK macro will behave.
#                 The macro is used to check pointers inside the functions
#                 against NULL. There are four settings for ARGTYPE. When
#                 set to 0, it will have the default behaviour of printing
#                 a message to stderr and raising a SIGABRT signal. This is
#                 provided so all platforms that use LibTomCrypt can have an
#                 error that functions similarly. When set to 1, it will
#                 simply pass on to the assert() macro. When set to 2, the
#                 macro will display the error to stderr then return
#                 execution to the caller. This could lead to a segmentation
#                 fault (e.g. when a pointer is NULL) but is useful if you
#                 handle signals on your own. When set to 3, it will resolve
#                 to a empty macro and no error checking will be performed.
#                 Finally, when set to 4, it will return CRYPT_INVALID_ARG
#                 to the caller.
#
# LTC_TEST        When this has been deﬁned the various self–test functions
#                 (for ciphers, hashes, prngs, etc) are included in the
#                 build. This is the default conﬁguration. If LTC_NO_TEST
#                 has been deﬁned, the testing routines will be compacted
#                 and only return CRYPT_NOP.
#
# LTC_NO_FAST     When this has been deﬁned the library will not use faster
#                 word oriented operations. By default, they are only enabled
#                 for platforms which can be auto-detected. This macro
#                 ensures that they are never enabled.
#
# LTC_FAST        This mode (auto-detected with x86 32,x86 64 platforms with
#                 GCC or MSVC) conﬁgures various routines such as ctr
#                 encrypt() or cbc encrypt() that it can safely XOR multiple
#                 octets in one step by using a larger data type. This has
#                 the beneﬁt of cutting down the overhead of the respective
#                 functions.
#
#                 This mode does have one downside. It can cause unaligned
#                 reads from memory if you are not careful with the
#                 functions. This is why it has been enabled by default only
#                 for the x86 class of processors where unaligned accesses
#                 are allowed. Technically LTC_FAST is not portable since
#                 unaligned accesses are not covered by the ISO C
#                 speciﬁcations. In practice however, you can use it on
#                 pretty much any platform (even MIPS) with care.
#
#                 By design the fast mode functions won’t get unaligned on
#                 their own. For instance, if you call ctr encrypt() right
#                 after calling ctr start() and all the inputs you gave are
#                 aligned than ctr encrypt() will perform aligned memory
#                 operations only. However, if you call ctr encrypt() with
#                 an odd amount of plaintext then call it again the CTR pad
#                 (the IV) will be partially used. This will cause the ctr
#                 routine to ﬁrst use up the remaining pad bytes. Then if
#                 there are enough plaintext bytes left it will use whole
#                 word XOR operations. These operations will be unaligned.
#                 The simplest precaution is to make sure you process all
#                 data in power of two blocks and handle remainder at the
#                 end. e.g. If you are CTR’ing a long stream process it in
#                 blocks of (say) four kilobytes and handle any remaining
#                 incomplete blocks at the end of the stream.
#
#                 If you do plan on using the LTC_FAST mode you have to also
#                 deﬁne a LTC_FAST_TYPE macro which resolves to an optimal
#                 sized data type you can perform integer operations with.
#                 Ideally it should be four or eight bytes since it must
#                 properly divide the size of your block cipher (e.g. 16
#                 bytes for AES). This means sadly if you’re on a platform
#                 with 57–bit words (or something) you can’t use this mode.
#                 So sad.
#
# LTC_NO_ASM      When this has been deﬁned the library will not use any
#                 inline assembler. Only a few platforms support assembler
#                 inlines but various versions of ICC and GCC cannot handle
#                 all of the assembler functions.
#
# LTC_SMALL_CODE  When this is defined some of the code such as the Rijndael
#                 and SAFER+ ciphers are replaced with smaller code variants.
#                 These variants are slower but can save quite a bit of code
#                 space.

when isMainModule:
  const ccFlags = " -DARGTYPE=4"
else:
  const ccFlags = " -DARGTYPE=4 -DNO_LTC_TEST"

{.passC: "-I " & srcIncDir & ccFlags.}

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
  ShaFfData* = array[32, uint8]
  ShaFfState* = tuple
    length: uint64
    state:  array[8, uint32]
    curlen: uint32
    buf:    array[64, uint8]

proc ltc_sha256_init(md: ptr ShaFfState): cint {.cdecl, importc.}
  ## Init hash descriptor.
  ##
  ## The function will return
  ##  * isCryptInvalidArg -- illegal null pointer argument
  ## or isCryptOk, otherwise

proc ltc_sha256_process(md: ptr ShaFfState;
                        p: pointer; n: culong): cint {.cdecl, importc.}
  ## Process hash data.
  ##
  ## The function will return
  ##  * isCryptInvalidArg   -- illegal (eg. null pointer) argument
  ##  * isCryptHashOverflow -- very large or neg. n (counter size overflow)
  ## or isCryptOk, otherwise

proc ltc_sha256_done(md: ptr ShaFfState; p: pointer): cint {.cdecl, importc.}
  ## Finalise hash data, p referes to a 32 byte data buffer.
  ##
  ## The function will return
  ##  * isCryptInvalidArg   -- illegal (eg. null pointer) argument
  ##  * isCryptHashOverflow -- very large n (counter size overflow)
  ## or isCryptOk, otherwise

# ----------------------------------------------------------------------------
# Public interface
# ----------------------------------------------------------------------------

proc getShaFf*(md: var ShaFfState) =
  ## Init sha-256 hash descriptor.
  discard ltc_sha256_init(addr md)

proc shaFfData*(md: var ShaFfState; data: pointer; size: int) {.inline.} =
  ## Add hash data, size should be smaller than 2^30
  if ltc_sha256_process(addr md, data, size.culong) != 0:
    quit "shaFfData: arg error"

proc shaFfDone*(md: var ShaFfState; rc: ptr ShaFfData) {.inline.} =
  ## finalise hash
  if ltc_sha256_done(addr md, rc) != 0:
    quit "shaFfDone: arg error"
  (addr md).zeroMem(md.sizeof)

proc shaFfDone*(md: var ShaFfState; rc: var ShaFfData) {.inline.} =
  ## finalise hash
  md.shaFfDone(addr rc)

proc shaFfDone*(md: var ShaFfState): ShaFfData {.inline.} =
  ## finalise hash
  md.shaFfDone(result)

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:
  type
    ShaFfConst = enum
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
  proc shaFfConst(n: cint): cstring {.cdecl, importc: "ltc_const".}
  proc shaFfTest():         cint    {.cdecl, importc: "ltc_sha256_test".}
  proc zShaFfSpecs():       pointer {.cdecl, importc: "ltc_sha256_specs".}

  proc toSeq(a: ShaFfData): seq[int8] =
    result = newSeq[int8](a.len)
    for n in 0..<a.len:
      result[n] = a[n].int.toU8

  proc tShaFfSpecs(): seq[int] =
    result = newSeq[int](0)
    var
      p: ShaFfState
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
      var s = shaFfConst(n.cint)
      if s.isNil:
        break
      # echo ">>> ", $s, " >> ", $(n.ShaFfConst)
      doAssert $s == $(n.ShaFfConst)
      n.inc
    # echo ">> ", n, " >> ", ShaFfConst.high.ord
    doAssert n == 1 + ShaFfConst.high.ord

  if true: # external self test
    var n = shaFfTest()
    #echo ">> ", n
    doAssert n.ShaFfConst == CRYPT_OK

  if true: # test state descriptor layout
    var
      a: array[6,cint]
      v = tShaFfSpecs()
    (addr a[0]).copyMem(zShaFfSpecs(), sizeof(a))
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
          h: ShaFfState
          v: ShaFfData
        h.getShaFf
        h.shaFfData(addr sIn[0], sIn.len)
        h.shaFfDone(v)
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
          h: ShaFfState
        h.getShaFf()
        h.shaFfData(addr sIn[0], sIn.len)
        var
          v = h.shaFfDone
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
