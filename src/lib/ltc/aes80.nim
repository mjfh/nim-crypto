# -*- nim -*-
#
# $Id$
#

import
  os, sequtils, strutils, macros

# ----------------------------------------------------------------------------
# AES compiler
# ----------------------------------------------------------------------------

template getCwd: string =
  instantiationInfo(-1, true).filename.parentDir

const
  cwd       = getCwd                               # starts with current ..
  D         = cwd[2 * (cwd[1] == ':').ord]         # .. DirSep, may differ ..
  srcIncDir = cwd & D & "headers"                  # .. from target DirSe
  srcSrcDir = cwd & D & "aesd"
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

const
  stdCcFlags = " -DARGTYPE=4 -DLTC_SMALL_CODE" &
               " -DLTC_NO_CIPHERS -DLTC_RIJNDAEL"

when isMainModule:
  const ccFlags = stdCcFlags
else:
  const ccFlags = stdCcFlags & " -DNO_LTC_TEST"

{.passC: "-I " & srcIncDir & ccFlags.}

{.compile: srcSrcDir & D & "ltc_aes.c".}
{.compile: srcExtDir & D & "ltc_crypt-const.c".}
{.compile: srcExtDir & D & "ltc_crypt-argchk.c".}
{.compile: srcExtDir & D & "ltc_zeromem.c".}

# ----------------------------------------------------------------------------
# Interface ltc/aes
# ----------------------------------------------------------------------------

const
  isCryptOk = 0
  # isCryptInvalidArg   = 16
  # isCryptHashOverflow = 25

type
  RijndaelKey* = tuple
    eK: array[60, uint32]   # ulong32 eK[60]
    dK: array[60, uint32]   # ulong32 dK[60];
    nR: cint

  Aes80Key* = tuple
    rndl: RijndaelKey       # symmetric encryption key
    pad:  cint              # occures on 32bit machines due to union embedding

  Aes80Array* = array[16,uint8]
  Aes80Data*  = Aes80Array | array[16,int8]


proc rijndael_setup(key: pointer; kLen: cint;
                    nRnds: cint; sKey: ptr Aes80Key): cint {.cdecl, importc.}
  ## Initialize the AES (Rijndael) block cipher
  ##
  ## Arguments:
  ##   key    --  [in] The symmetric key you wish to pass
  ##   kLen   --  [in] The key length in bytes
  ##   nRnds  --  [in] The number of rounds desired (0 for default)
  ##   sKey   -- [out] The key in as scheduled by this function.
  ##
  ## Returns:
  ##   isCryptOk if successful

# proc rijndael_done(sKey: ptr Aes80Key) {.cdecl, importc.}
#  ## Terminate the context
#  ##
#  ## Argument:
#  ##   sKey    -- [in] The key in as scheduled by this function.

proc rijndael_keysize(kSize: ptr cint): cint {.cdecl, importc.}
  ## Gets suitable key size
  ##
  ## Argument:
  ##   kSize -- [in/out] The length of the recommended key (in bytes). This
  ##                     function will store the suitable size back in this
  ##                     variable (16, 24, or 32).
  ## Returns:
  ##   isCryptOk if the input key size is acceptable.

proc rijndael_ecb_decrypt(ct, pt: pointer;
                          sKey: ptr Aes80Key): cint {.cdecl, importc.}
  ## Decrypts a block of text with AES
  ##
  ## Arguments:
  ##   ct    --  [in] The input ciphertext (16 bytes)
  ##   pt    -- [out] The output plaintext (16 bytes)
  ##   sKey  --  [in] The key as scheduled
  ##
  ## Returns:
  ##   isCryptOk if successful

proc rijndael_ecb_encrypt(pt, ct: pointer;
                          sKey: ptr Aes80Key): cint {.cdecl, importc.}
  ## Encrypts a block of text with AES
  ##
  ## Arguments:
  ##   pt    --  [in] The input plain text (16 bytes)
  ##   ct    -- [out] The output cipher text (16 bytes)
  ##   sKey  --  [in] The key as scheduled
  ##
  ## Returns:
  ##   isCryptOk if successful

# ----------------------------------------------------------------------------
# Debugging helper
# ----------------------------------------------------------------------------

proc fromHexSeq(buf: seq[int8]; sep = " "): string =
  ## dump an array or a data sequence as hex string
  buf.mapIt(it.toHex(2).toLowerAscii).join(sep)

proc fromHexSeq(buf: Aes80Data; sep = " "): string =
  var q = newSeq[int8](buf.len)
  for n in 0..<buf.len: q[n] = buf[n].int.toU8
  result = q.fromHexSeq(sep)

proc toHexSeq(s: string): seq[int8] =
  ## Converts a hex string stream to a byte sequence, it raises an
  ## exception if the hex string stream is incorrect.
  result = newSeq[int8](s.len div 2)
  for n in 0..<result.len:
    result[n] = s[2*n..2*n+1].parseHexInt.toU8
  doAssert s == result.mapIt(it.toHex(2).toLowerAscii).join

proc toAes80Array(s: string): Aes80Array =
  var q = s.toHexSeq
  doAssert q.len == result.len
  (addr result[0]).copyMem(addr q[0], result.len)

# ----------------------------------------------------------------------------
# Public interface
# ----------------------------------------------------------------------------

proc getAes80*[T: string|seq[int8]](
     x: var Aes80Key; key: T; nRnds = 0): bool {.inline.} =
  ## Initialize AES
  let keyPtr = cast[pointer](unsafeAddr key[0])
  if isCryptOk == rijndael_setup(keyPtr, key.len.cint, nRnds.cint, addr x):
    result = true
  else:
    (addr x).zeroMem(x.sizeof)

proc clearAes80*(x: var Aes80Key) {.inline.} =
  ## Terminate AES context
  # (addr x).rijndael_done
  (addr x).zeroMem(x.sizeof)

proc aes80Encrypt(x: var Aes80Key;
                  pOut, pIn: ptr Aes80Data): bool {.inline.} =
  ## Encrypt a data block
  isCryptOk == rijndael_ecb_encrypt(pIn, pOut, addr x)

proc aes80Decrypt(x: var Aes80Key;
                  pOut, pIn: ptr Aes80Data): bool {.inline.} =
  ## Decrypt a data block
  isCryptOk == rijndael_ecb_decrypt(pIn, pOut, addr x)

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:

  # verify Aes80Key descriptor layout in C and NIM
  {.compile: srcSrcDir & D & "ltc_aes80specs.c".}
  proc zAes80Specs(): pointer {.cdecl, importc: "ltc_aes80_specs".}
  proc tAes80Specs(): seq[int] =
    result = newSeq[int](0)
    var
      p: Aes80Key
      a = cast[int](addr p)
      m = int.sizeof - 1
      n = cast[int](addr p.pad) - a
    result.add(cast[int](addr p.rndl.eK) - a)
    result.add(cast[int](addr p.rndl.dK) - a)
    result.add(cast[int](addr p.rndl.nR) - a)
    result.add(n)
    # struct into union embedding: get next alignment boundary
    result.add((n + m) and not m)
    result.add(0xffff)
  var
    a: array[6,cint]
    v = tAes80Specs()
  (addr a[0]).copyMem(zAes80Specs(), sizeof(a))
  # echo ">> ", v, " >> ", a.mapIt(int, it)
  doAssert v == a.mapIt(int, it)

  # invoke self test in C code
  proc rijndael_test(): cint {.cdecl, importc.}
  # echo ">>> ", rijndael_test()
  doAssert isCryptOk == rijndael_test()

  if true: # run external test (checks interface)
    var
      testVect = @[
        #
        # //nvlpubs.nist.gov/nistpubs/Legacy/SP
        #      /nistspecialpublication800-38a.pdf
        # Appendix F: Example Vectors for Modes of Operation of the AES
        # F1.1 ECB Example Vectors
        # F.1.1 ECB-AES128.Encrypt
        #
        ("F.1.1 - #1",
         "2b7e151628aed2a6abf7158809cf4f3c",  # key
         "6bc1bee22e409f96e93d7e117393172a",  # Plaintext, Input Block
         "3ad77bb40d7a3660a89ecaf32466ef97"), # Output Block, Ciphertext
        ("F.1.1 - #2",
         "2b7e151628aed2a6abf7158809cf4f3c",
         "ae2d8a571e03ac9c9eb76fac45af8e51",
         "f5d3d58503b9699de785895a96fdbaaf"),
        ("F.1.1 - #3",
         "2b7e151628aed2a6abf7158809cf4f3c",
         "30c81c46a35ce411e5fbc1191a0a52ef",
         "43b1cd7f598ece23881b00e3ed030688"),
        ("F.1.1 - #4",
         "2b7e151628aed2a6abf7158809cf4f3c",
         "f69f2445df4f9b17ad2b417be66c3710",
         "7b0c785e27e8ad3f8223207104725dd4")]

    for n in 0..<testVect.len:
      var (tInfo, tKey, tPlain, tCipher) = testVect[n]
      when not defined(check_run):
        echo ">>> ", tInfo
      block:
        var
          key, zKy: Aes80Key
          pln = tPlain.toAes80Array
          cph, qln: Aes80Array
        doAssert true == key.getAes80(tKey.toHexSeq)

        discard key.aes80Encrypt(addr cph, addr pln)
        var nCipher = cph.fromHexSeq("")
        # echo ">>> nCipher=", nCipher, " tCipher=", tCipher
        doAssert nCipher == tCipher

        discard key.aes80Decrypt(addr qln, addr cph)
        var nPlain = qln.fromHexSeq("")
        # echo ">>> nPlain=", nPlain, " tPlain=", tPlain
        doAssert nPlain == tPlain
        doAssert pln == qln

        key.clearAes80
        # echo ">>> key=", key
        doAssert key == zKy

#  when not defined(check_run):
#    echo "*** not yet"

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
