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
## This module implements a simple stream cypher session based on an ECC
## public/private key scheme and the ChaCha20 stream cipher. This might be
## useful for generating reports anonymously which can be decoded only
## by the owner of a private key. All produced ciphertext is base64 encoded
## or can be left raw.
##
## The scheme supports three key public slots so there are up to three
## different private key holder destinations possible.
##
## This software is ment to work on small systems using little
## system resources. It is not supposed to be used for serious security
## requirements - think of using TLS or GPG(ie. PGP) if that is needed.
##
## USE THIS MODULE AT YOUR OWN RISK.
##
##
## Example 1:
##
## .. code-block::
##
##    # message receiver generates public/private key pair
##    import
##      ecckey
##    var
##      mRcvPrvKey: EccPrvKey
##      mRcvPubKey: EccPubKey
##
##    mRcvPrvKey.getEccPrvKey
##    mRcvPubKey.getEccPubKey(addr mRcvPrbKey)
##
##
## Now the public key mRcvPubKey is passed to the sender while
## the pivate key mRcvPrvKey is kept secret. The sender can now
## start ecrypting data:
##
## .. code-block::
##
##    # message sender prepares an encrypted message
##    import
##      xcrypt
##    var
##      iCtx: XCryptCtx
##      pKey: array[3,ptr EccPubKey]
##
##    # create a verification pattern
##    var verifier = getXVerfier()
##
##    # fill up to three public keys, only one is used here
##    pKey[0] = addr mRcvPubKey
##
##    # start session
##    var data = iCtx.getXB64Encrypt(addr pKey, addr verifier)
##
##    # append more data, assume there is a secret text message msgText
##    data &= iCtx.xB64Encrypt(addr msgText[0], msgText.len)
##
##
## Now the strings 'data' and 'verifier' are passed back to the receiver
## which holds the private key generated earlier. The receiver can now
## decode this message with a similar scheme:
##
## .. code-block::
##
##    # message receiver decrypts message
##    import
##      xcrypt
##    var
##      oCtx: XCryptCtx
##
##    # start session
##    var preamble = oCtx.getXB64Decrypt(data, addr mRcvPrvKey, addr verifier)
##
##    # verify, preamble it is at least 380 if session could be started
##    doAssert 0 < preamble
##
##    # extract encrypred message from 'data'
##    var hidden = data[preamble..<data.len]
##
##    # decode message => msgText
##    var msg = oCtx.xB64Decrypt(hidden)
##
##    # this only works if msgText was not really secret :)
##    doAssert msg == msgText
##
##
##
## Example 2::
##
## .. code-block::
##
##    import
##      ecckey, xcrypt
##
##    # simple text block encryption
##    proc encrypt(s: string; pub: ptr EccPubKey): string =
##      var
##        ctx: XCryptCtx
##        keys = [pub, nil, nil]
##        chl  = getXVerfier()
##      result = ctx.getXRawEncrypt(addr keys, addr chl) &
##               ctx.xRawEncrypt(unsafeAddr s[0], buf.len)
##      ctx.clearXCrypt
##
##    # ... and decryption
##    proc decrypt(s: string; prv: ptr EccPrvKey): string =
##      var
##        ctx: XCryptCtx
##        chl = getXVerfier()
##        pre = ctx.getXRawDecrypt(s, prv, addr chl)
##      doAssert 0 < pre
##      result = ctx.xRawDecrypt(unsafeAddr s[pre], buf.len - pre)
##      ctx.clearXCrypt
##
##    # ... can be used as follows
##    var
##      prvKey: EccPrvKey
##      pubKey: EccPubKey
##
##    prvKey.getEccPrvKey
##    pubKey.getEccPubKey(addr prvKey)
##
##    var text = "Hi There"
##    doAssert text.encrypt(addr pubKey).decrypt(addr prvKey) == text
##    doAssert text.encrypt(addr pubKey)                      != text
##
##
## Remarks:
##
## * The session instantiation protocol uses the public/private key scheme
##   implemented in in the 'sesskey' module. The receiver extracts one of
##   three possible session keys from the session header and tries to
##   decrypt the next line from the header which contains some known text
##   (passed on as 'verifier' in the above example). If the text could be
##   decrypted, the the key is accepted. Otherwise the next key is tried.
##
##   The known (plain) text for testing is a byte array of type 'XPattern'
##   where a non-zero byte means it must be matched after decryption. A zero
##   byte is ignored. Use the function getXVerfier() in order to generate
##   a proper 'XPattern' verifier.
##
## * There is a limitation in ChaCha20 where the stream cipher is only
##   defined for streams smaller than 2^70 bytes (no re-keying implemented
##   here).
##

import
  base64, chacha/chacha, ecckey, rnd64, sesskey, strutils

export
  ecckey

const
  InLinelen  = 57
  OutLineLen = 76
  OutLineBlk = 5 * OutLineLen
  xIntroLen*     = InLinelen
  xRawHeaderLen* = 5 * InLinelen

assert 57 * 4 == 76 * 3       # verify full base64 line width

assert SessKey.sizeof == ChaChaKey.sizeof

type
  XPattern* = array[xIntroLen, int8] ## pattern for checking key validity
  XCryptCtx* = tuple                 ## stream cipher context
    ccc: ChaChaCtx

  XCryptData = tuple
    nonce: SessNonce
    key:   array[3,SessKey]
    prv:   array[3,ptr EccPrvKey]
    iLine: array[xIntroLen, uint8] # base64 sucks - crashes on int8 array
    oLine: array[xIntroLen, uint8]

# ----------------------------------------------------------------------------
# Private functions
# ----------------------------------------------------------------------------

proc startXEncrypt(ctx: var XCryptCtx;
                   xdt: var XCryptData;
                   pub: ptr array[3,ptr EccPubKey];
                   intro: ptr XPattern): string =
  var
    kPtr = cast[ptr ChaChaKey](addr xdt.key[0])
    nPtr = cast[ptr ChaChaIV](addr xdt.nonce)

  result = xdt.key[0].getRawSessHeader(xdt.nonce,pub) # session parameters

  for n, w in rnd8items(xdt.oLine.len):               # first output line
    if intro[n] == 0:                                 # generated by pattern
      xdt.iLine[n] = w.uint8
    else:
      xdt.iLine[n] = intro[n].uint8

  getChaCha(ctx.ccc, kPtr, nPtr)
  chachaAnyCrypt(ctx.ccc, addr xdt.oLine, addr xdt.iLine, InLinelen)

  # append xpattern line
  result.setLen(5 * InLinelen)
  (addr result[4 * InLinelen]).copyMem(addr xdt.oLine[0], InLinelen)


proc startXDecrypt(ctx: var XCryptCtx;
                   xdt: var XCryptData;
                   hdr: string;
                   prv: ptr EccPrvKey; vfy: ptr XPattern): bool =
  var
    zero: SessKey                                     # compare key == zero
    nPtr = cast[ptr ChaChaIV](addr xdt.nonce)

  if InLinelen <= 5 * hdr.len:
    xdt.prv[0] = prv
    xdt.prv[1] = prv
    xdt.prv[2] = prv

    # extract keys from stream header
    xdt.key.extrRawSessMsg(xdt.nonce, hdr, addr xdt.prv)

    # try for each key to decrypt the challenge data
    for n in 0..<xdt.key.len:
      if xdt.key[n] == zero:                          # ignore zero key slot
        continue
      var
        kPtr = cast[ptr ChaChaKey](addr xdt.key[n])
        line = hdr[(4 * InLinelen) .. <(5 * InLinelen)]

      # decrypt challenge with current key
      getChaCha(ctx.ccc, kPtr, nPtr)                  # try key for decryption
      chachaAnyCrypt(ctx.ccc, addr xdt.oLine,         # decrypt line
                     unsafeAddr hdr[4 * InLinelen], InLinelen)

      block verify:
        for n in 0..<xdt.oLine.len:                   # check verifier pattern
          if vfy[n] != 0 and xdt.oLine[n] != vfy[n].uint8:
            break verify
        return true                                   # found matching key
        # end block verify

    (addr ctx).zeroMem(ctx.sizeof)                    # clean up key
    # end if

# ----------------------------------------------------------------------------
# Public functions
# ----------------------------------------------------------------------------

proc getXVerfier*(s = "HELLO WORLD"): XPattern =
  ## creates a key validity checker needed for the instantiation
  ## session protocol
  var
   sLen = min(s.len, InLinelen - 20)
   offs = (InLinelen - sLen) div 2
  for i in 0..<sLen:                                  # center s
    result[offs + i] = s[i].ord.int8



proc getXB64Encrypt*(ctx: var XCryptCtx;
                     pub: ptr array[3,ptr EccPubKey];
                     challenge: ptr XPattern): string =
  ## Start a new encryption session. It returns a base64 encoded text
  ## header, the initial part of the cipher data stream.
  var xdt: XCryptData
  result = ctx.startXEncrypt(xdt, pub, challenge).encode

  if result[result.len-1] != '\l':                   # make sure message
    result &= "\r\l"                                 # terminates with CRLF
  (addr xdt).zeroMem(xdt.sizeof)                     # clear key data


proc getXRawEncrypt*(ctx: var XCryptCtx;
                     pub: ptr array[3,ptr EccPubKey];
                     challenge: ptr XPattern): string =
  ## same as getXB64Encrypt() but returns binary instead of base64 data
  var xdt: XCryptData
  result = ctx.startXEncrypt(xdt, pub, challenge)
  (addr xdt).zeroMem(xdt.sizeof)                     # clear key data


proc getXB64Decrypt*(ctx: var XCryptCtx;
                     b64: string;
                     prv: ptr EccPrvKey;
                     challenge: ptr XPattern): int =
  ## Start a decryption session by decoding the base 64encoded header of
  ## the cipher data stream. It returns the length consumed.
  var
    xdt: XCryptData
    data = b64.decode

  if ctx.startXDecrypt(xdt, data, prv, challenge):

    # find end of base64 encoded block (format considerations apply)
    var inx = b64.find('\l', start = OutLineBlk)
    if 0 < inx:
      result = 1 + inx                               # found matching key
    else:
      (addr ctx).zeroMem(ctx.sizeof)                 # reset key material

  (addr xdt).zeroMem(xdt.sizeof)                     # clear key data


proc getXRawDecrypt*(ctx: var XCryptCtx;
                     bin: string;
                     prv: ptr EccPrvKey; challenge: ptr XPattern): int =
  ## same as getXB64Decrypt() but for binary header data instead of base64
  var xdt: XCryptData
  if ctx.startXDecrypt(xdt, bin, prv, challenge):
    result = 5 * InLinelen
  (addr xdt).zeroMem(xdt.sizeof)                     # clear key data


proc xB64Encrypt*(ctx: var XCryptCtx; p: pointer; n: int): string {.inline.} =
  ## encrypt next base64 session data
  var buf = newString(n)
  chachaAnyCrypt(ctx.ccc, addr buf[0], p, n)
  result = buf.encode

proc xB64Encrypt*(ctx: var XCryptCtx; s: string): string =
  ## encrypt next base64 session data
  ctx.xB64Encrypt(unsafeAddr s[0], s.len)

proc xRawEncrypt*(ctx: var XCryptCtx; p: pointer; n: int): string {.inline.} =
  ## encrypt binary session data
  result = newString(n)
  chachaAnyCrypt(ctx.ccc, addr result[0], p, n)

proc xRawEncrypt*(ctx: var XCryptCtx; s: string): string =
  ctx.xRawEncrypt(unsafeAddr s[0], s.len)


proc xB64Decrypt*(ctx: var XCryptCtx; b64Enc: string): string {.inline.} =
  ## decrypt base64 session data
  result = b64Enc.decode
  chachaAnyCrypt(ctx.ccc, addr result[0], addr result[0], result.len)

proc xRawDecrypt*(ctx: var XCryptCtx; p: pointer; n: int): string {.inline.} =
  ## decrypt binary session data
  result = newString(n) # same as xRawEncrypt()
  chachaAnyCrypt(ctx.ccc, addr result[0], p, n)

proc xRawDecrypt*(ctx: var XCryptCtx; trg, src: pointer; n: int) {.inline.} =
  ## decrypt binary session data
  chachaAnyCrypt(ctx.ccc, trg, src, n)

proc clearXCrypt*(ctx: var XCryptCtx) {.inline.} =
  ## clean up after session has finished
  (addr ctx).zeroMem(ctx.sizeof)

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:

  import
    sequtils

  # need also set useFixedInitStr in rnd64 to produce the same random sequence
  rnd64init(123)

  proc xpatgen(s: string): XPattern =
    for n in 0..<min(s.len,result.len):
      if s[n] != '.':
        result[n] = s[n].ord.int8

  const
    text = """
# The author or authors of this code dedicate any and all copyright interest
# in this code to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and successors.
# We intend this dedication to be an overt act of relinquishment in
# perpetuity of all present and future rights to this code under copyright
# law
"""
    tPrvKey: EccPrvKey =
      (prvKey: [0x80u8,0x6Fu8,0xB0u8,0x44u8,0xC7u8,0xE1u8,0x5Fu8,0xA8,
                0x71u8,0xCAu8,0xF6u8,0xD9u8,0x77u8,0x7Au8,0x91u8,0xB2,
                0xF8u8,0x93u8,0x41u8,0x90u8,0x1Fu8,0x85u8,0x5Eu8,0x17,
                0xC4u8,0xF2u8,0xD8u8,0xA6u8,0xB4u8,0x34u8,0xBFu8,0x6B])

    tPubKey: EccPubKey =
      (pubKey: [0x30u8,0xA3u8,0xCCu8,0x2Bu8,0xC6u8,0x7Fu8,0xC7u8,0x15,
                0x01u8,0xE8u8,0x58u8,0xC2u8,0x82u8,0x66u8,0x64u8,0x3B,
                0x4Fu8,0x69u8,0x36u8,0x9Cu8,0x92u8,0x0Eu8,0xD0u8,0xCE,
                0x13u8,0x74u8,0x7Fu8,0xABu8,0x43u8,0x7Au8,0x7Du8,0x0C])
    nLoop = 5

  var
    iCtx: XCryptCtx
    oCtx: XCryptCtx

    pub = tPubKey
    pba = [nil, addr pub, nil]
    prv = tPrvKey
    pat = "Hello World!".getXVerfier

  var b = text.getXVerfier
  doAssert b[0]       == 0
  doAssert b[b.len-1] == 0

  if true:
    var data = iCtx.getXB64Encrypt(addr pba, addr pat)
    for n in 0..nLoop:
      data &= iCtx.xB64Encrypt(text)

    var pre = getXB64Decrypt(oCtx, data, addr prv, addr pat)
    doAssert 0 < pre

    var msg = oCtx.xB64Decrypt(data[pre..<data.len])
    for n in 0..nLoop:
      var a = msg[0..<text.len]
      msg   = msg[text.len..<data.len]
      doAssert a == text
    doAssert msg == ""


  # now the same with raw functions
  if true:
    var
      data = iCtx.getXRawEncrypt(addr pba, addr pat)
    for n in 0..nLoop:
      var u = data.len
      data &= iCtx.xRawEncrypt(text)

    var pre = oCtx.getXRawDecrypt(data, addr prv, addr pat)
    doAssert 0 < pre

    var msg = oCtx.xRawDecrypt(addr data[pre], data.len - pre)
    for n in 0..nLoop:
      var a = msg[0..<text.len]
      msg   = msg[text.len..<data.len]
      doAssert a == text
    doAssert msg == ""

#  when not defined(check_run):
#    echo "*** not yet"

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
