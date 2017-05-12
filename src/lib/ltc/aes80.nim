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
  ltc  / [aes80desc, ltc_const],
  misc / [prjcfg]

export
  aes80desc

# ----------------------------------------------------------------------------
# AES compiler
# ----------------------------------------------------------------------------

const
  stdCcFlgs = " -I " & "headers".nimSrcDirname

when isMainModule:
  const ccFlags = stdCcFlgs
else:
  const ccFlags = stdCcFlgs & " -DNO_LTC_TEST"

{.passC: ccFlags.}

{.compile: "aesd/ltc_aes.c"           .nimSrcDirname.}
{.compile: "crypt/ltc_crypt-argchk.c" .nimSrcDirname.}
{.compile: "crypt/ltc_zeromem.c"      .nimSrcDirname.}

# ----------------------------------------------------------------------------
# Interface ltc/aes
# ----------------------------------------------------------------------------

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

#proc rijndael_keysize(kSize: ptr cint): cint {.cdecl, importc.}
#  ## Gets suitable key size
#  ##
#  ## Argument:
#  ##   kSize -- [in/out] The length of the recommended key (in bytes). This
#  ##                     function will store the suitable size back in this
#  ##                     variable (16, 24, or 32).
#  ## Returns:
#  ##   isCryptOk if the input key size is acceptable.

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

when isMainModule:
  proc fromHexSeq(buf: seq[int8]; sep = " "): string =
    ## dump an array or a data sequence as hex string
    buf.mapIt(it.toHex(2).toLowerAscii).join(sep)

  proc fromHexSeq(buf: Aes80Data; sep = " "): string =
    var q = newSeq[int8](buf.len)
    for n in 0..<buf.len:
      q[n] = buf[n].int.toU8
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

proc aes80Encrypt*(x: var Aes80Key;
                   pOut, pIn: ptr Aes80Data): bool {.inline.} =
  ## Encrypt a data block
  isCryptOk == rijndael_ecb_encrypt(pIn, pOut, addr x)

proc aes80Decrypt*(x: var Aes80Key;
                   pOut, pIn: ptr Aes80Data): bool {.inline.} =
  ## Decrypt a data block
  isCryptOk == rijndael_ecb_decrypt(pIn, pOut, addr x)

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:

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
