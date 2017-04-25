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
## Simple public/private key arrangement for low security applications.
## The key negotiation woks as follows.
##
## Prerequisites::
##
##      P     -- known public key
##      k     -- secret message to be shared with owner of public key P
##      H()   -- a cryptographic hash function
##      S()   -- ECC scheme where, given a secret key w one can derive
##               a shared key S(w,P) as follows. Let
##                  P = p * G  (p = private, G = public generator)
##                  W = w * G  (w = private)
##               then, knowing only (p,W) or (w,P) the shared secret
##                  S = p * w * G
##               can retrieved. In particular
##                  S(w,P) = S(p,W)
##
## Encryption E() of message k::
##
##     N              -- generate some random data (nonce)
##     (w,W)          -- generate ephemeral private key w and derive public key W
##     S = S(w,P)     -- construct ephemeral session key using public key P
##     H = H(S,N)     -- hash S and N together
##     K = k(+)H      -- encrypt k by xoring against H
##     E(k) = (K,W,N) -- now, (K,W,N) is the full encryption E(k) of message k
##
## Decryption D() of E(k) by owner of public key P::
##
##     (p,P)          -- use the public/private key pair (p is privy to the owner of P)
##     S = S(p,W)     -- calculate S, it is the same as S(w,P)
##     H = H(S,N)     -- hash S and N together
##     k = K(+)H      -- undo xor from above in order to retrieve k
##
## Note the the receiver of an encrypted message 'k' has no means to check
## who the sender was by this scheme alone. If this is important it has to
## be implemented in the subsequent session intialised with 'k'.
##
## Remarks:
##
## * This schema resembles somehow an El Gamal encryption scheme over ECC
##   (e.g. Sunuwar, R. and Samal, S.K., 2015. Elgamal Encryption using
##   Elliptic Curve Cryptography). The difference here is that the real
##   El Gamal scheme involves the solution of::
##
##        given x find some y, w so that (x,y) = w * G
##
##   which needs more extensive calculation for the square root
##   of a scalar x mod 2^{252} - 19 (ed25519, see W'pedia)
##
## * I do not know of any cryptanalysis of this scheme.
##
## * Implement Integrated Encryption Scheme (IES, see W'pedia) if a proven
##   secure scheme is needed. This also solves the problem of mutual
##   authentication.
##
## Session header layout implemented here for a 32 byte message 'k'::
##
##     |     0   +----------+
##     |         |  W1      |    1, 2, or 3 ephemeral public keys W1, W2, W3
##     |    32   +----------+    that relate to one or more public keys P1,
##     |         |  W2      |    P2, P3 of of the receivers of this header
##     |    64   +----------+    with respect to scheme S() explained above
##     |         |  W3      |
##     |    96   +------+---+
##     |         |  N1  |        first nonce N1
##     |   114   +------+---+
##     |         |  K1      |
##     |   146   +----------+    1, 2, or 3 encrypted messages all with the
##     |         |  K2      |    same content 'k'
##     |   178   +----------+
##     |         |  K3      |
##     |   210   +------+---+
##     |         |  N2  |        second nonce N2
##     |   228   +------+
##
##
## All keys W1, W2, W3 and K1, K2, K3 are of length 32 bytes, the nonces
## N1, N2 are 18 bytes each. The total header length is 228 bytes which
## fits nicely in four base64 encoded lines of 76 character each. The
## hash function used for H() is SHA256 wkich also produces to 32 byte
## has results.
##
## This header encrypts the message 'k' as::
##
##     E1 = (K1,W1,N), E2 = (K2,W2,N), E3 = (K3,W3,N)
##
## where N is the concatenation of N1+N2.
##
## If there were three public keys P1, P2, P3 with known private keys
## p1, p2, and p3 then all encryptes representations decode properly
## the same messgae 'k'. In the worst case one decodes three different
## mesages and one has to guess which one is the right one.
##
#
import
  base64, ecckey, ltc/sha100, rnd64, strutils, uecc/uecc

export
  uecc

const
  InLinelen   = 57
  OutLineLen  = 76
  HdrBlkLen   = 2 * InLinelen   # header: 2 blocks with 2 lines each
  HdrTotalLen = 2 * HdrBlkLen

  SessKeyLen* = UEccScalarLen
  NonceLen*   = HdrTotalLen - 6 * SessKeyLen
  NonceLenH   = NonceLen div 2

assert 57 * 4 == 76 * 3       # verify full base64 line width
assert 20 < NonceLen
assert 2 * NonceLenH == NonceLen
assert SessKeyLen == EccSessKey.sizeof

type
  SessKey*   = array[SessKeyLen, uint8]
  SessNonce* = array[NonceLen,   uint8]
  SessData = tuple
    sMsg:     SessKey                    # encrypted message,     K
    sPubKey:  EccPubKey                  # session public key,    W
    sNonce:   SessNonce                  # nonce,                 N

    ePrvKey:  EccPrvKey                  # ephemeral private key
    eSessKey: EccSessKey                 # ephemeral session key, S
    eHash:    SessKey                    # ephemeral hash value,  H

    nKey: EccPubKey                      # throw away key for empty slots


assert SessKey.sizeof == EccSessKey.sizeof
assert SessKey.sizeof == EccPubKey.sizeof
assert SessKey.sizeof == EccPrvKey.sizeof
assert SessKey.sizeof == Sha100Data.sizeof

# ----------------------------------------------------------------------------
# Private helpers
# ----------------------------------------------------------------------------

proc makeSessKey(p: var SessKey) =
  for n, w in rnd8items(p.len):
    p[n] = w.uint8

proc makeNonce(p: var SessNonce) =
  for n, w in rnd8items(p.len):
    p[n] = w.uint8

proc mangle(p: var SessKey; key: ptr EccSessKey; nonce: ptr SessNonce) =
  var md: Sha100State
  assert key[].sizeof == Sha100Data.sizeof
  md.getSha100
  md.sha100Data(key, key[].sizeof)
  md.sha100Data(nonce, nonce[].sizeof)
  md.sha100Done(cast[ptr Sha100Data](addr p))

proc xorKeys(p: var SessKey; a, b: ptr SessKey) =
  for n in 0..<a[].len:
    p[n] = a[n] xor b[n]

# ----------------------------------------------------------------------------
# Private functions
# ----------------------------------------------------------------------------

proc doGetSessHeader(msg: var SessKey;
                     sdt: var SessData;
                     pub: ptr array[3,ptr EccPubKey]): string =
  msg.makeSessKey()                                # create session key
  sdt.sNonce.makeNonce()

  result = newString(HdrTotalLen)

  for n in 0..2:                                   # create header data
    var pubPtr = pub[n]

    if pub[n].isNil:                               # missing pubkey?
      sdt.ePrvKey.getEccPrvKey()                   # generate one and throw
      sdt.nKey.getEccPubKey(addr sdt.ePrvKey)      # .. it away when done
      pubPtr = addr sdt.nKey

    sdt.ePrvKey.getEccPrvKey()                           # ephemeral key pair
    sdt.sPubKey.getEccPubKey(addr sdt.ePrvKey)           # => (w,W)

    sdt.eSessKey.getEccSessKey(addr sdt.ePrvKey, pubPtr) # => S(w,P)
    sdt.eHash.mangle(addr sdt.eSessKey, addr sdt.sNonce) # => H(S,N)
    sdt.sMsg.xorKeys(addr msg, addr sdt.eHash)           # => K(+)H

    (addr result[            n * 32]).copyMem(addr sdt.sPubKey[0], SessKeyLen)
    (addr result[HdrBlkLen + n * 32]).copyMem(addr sdt.sMsg[0],    SessKeyLen)
    # end for

  (addr result[96            ]).copyMem(addr sdt.sNonce[0],         NonceLenH)
  (addr result[96 + HdrBlkLen]).copyMem(addr sdt.sNonce[NonceLenH], NonceLenH)



proc doExtrSessMsg(msg: var array[3,SessKey];
                   sdt: var SessData;
                   hdr: string; prv: ptr array[3,ptr EccPrvKey]) =

  if HdrTotalLen <= hdr.len:
    (addr sdt.sNonce[0        ])
       .copyMem(unsafeAddr hdr[96],             NonceLenH)
    (addr sdt.sNonce[NonceLenH])
       .copyMem(unsafeAddr hdr[96 + HdrBlkLen], NonceLenH)

    for n in 0..2:
      if prv[n].isNil:
        continue

      (addr sdt.sPubKey[0])
         .copyMem(unsafeAddr hdr[            n * 32], SessKeyLen)
      (addr sdt.sMsg[0])
         .copyMem(unsafeAddr hdr[HdrBlkLen + n * 32], SessKeyLen)

      sdt.eSessKey.getEccSessKey(prv[n], addr sdt.sPubKey) # => S(p,W)
      sdt.eHash.mangle(addr sdt.eSessKey, addr sdt.sNonce) # => H(S,N)
      msg[n].xorKeys(addr sdt.sMsg, addr sdt.eHash)        # => K(+)H
      # end for

# ----------------------------------------------------------------------------
# Public functions
# ----------------------------------------------------------------------------

proc getB64SessHeader*(msg:   var SessKey;
                       nonce: var SessNonce;
                       pub:   ptr array[3,ptr EccPubKey]): string =
  ## Creates a session header by encrypting a random meessage 'msg' with
  ## three ECC public keys given as argument (leave key slot nil). Returns
  ## the encrypted message as string and the generated message as SessKey
  ## (first var parameter).
  var sdt: SessData
  result = msg.doGetSessHeader(sdt, pub).encode.strip
  nonce = sdt.sNonce
  (addr sdt).zeroMem(sdt.sizeof)                     # clear key data

proc getB64SessHeader*(msg: var SessKey;
                       pub: ptr array[3,ptr EccPubKey]): string =
  var sdt: SessData
  result = msg.doGetSessHeader(sdt, pub).encode.strip
  (addr sdt).zeroMem(sdt.sizeof)                     # clear key data


proc getRawSessHeader*(msg:   var SessKey;
                       nonce: var SessNonce;
                       pub:   ptr array[3,ptr EccPubKey]): string =
  ## same as getB64SessHeader() but with binary 228 byte header returned
  ## rather than the base64 encoded version
  var sdt: SessData
  result = msg.doGetSessHeader(sdt, pub)
  nonce = sdt.sNonce
  (addr sdt).zeroMem(sdt.sizeof)                     # clear key data



proc extrB64SessMsg*(msg:    var array[3,SessKey];
                     nonce:  var SessNonce;
                     b64Hdr: string; prv: ptr array[3,ptr EccPrvKey]) =
  ## Decrypt session header and retrieve the message 'msg' in three
  ## variations. The position of the three message decodings correspond
  ## to the positions of the argument ECC private keys (ideally all three
  ## message variations are the same). Leave unused private key slots nil.
  ##
  ## Note: There is no means to check here whether the decoding of the
  ## shared message was correct.
  var
    sdt: SessData
    hdr = b64Hdr.decode
  msg.doExtrSessMsg(sdt, hdr, prv)
  nonce = sdt.sNonce
  (addr sdt).zeroMem(sdt.sizeof)                   # clear key data

proc extrB64SessMsg*(msg: var array[3,SessKey];
                     b64Hdr: string; prv: ptr array[3,ptr EccPrvKey]) =
  var
    sdt: SessData
    hdr = b64Hdr.decode
  msg.doExtrSessMsg(sdt, hdr, prv)
  (addr sdt).zeroMem(sdt.sizeof)                   # clear key data

proc extrRawSessMsg*(msg:    var array[3,SessKey];
                     nonce:  var SessNonce;
                     rawHdr: string;
                     prv: ptr array[3,ptr EccPrvKey]) =
  ## same as extrB64SessMsg() but with binary 228 byte header (or more) rather
  ## than the base64 encoded version
  var sdt: SessData
  msg.doExtrSessMsg(sdt, rawHdr, prv)
  nonce = sdt.sNonce
  (addr sdt).zeroMem(sdt.sizeof)                   # clear key data

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:

  import
    sequtils

  # need also set useFixedInitStr in rnd64 to produce the same random sequence
  rnd64init(123)

  proc ppHdr(s: string): string =
    proc show(s: string; a, b: int): string =
      result = ""
      if a <  10: result &= " "
      if a < 100: result &= " "
      result &= $a & ": "
      result &= s[a..<(a+b)].mapIt(it.ord.toHex(2)).join(" ")
    var
      n = 0
      q = newSeq[string](0)
      d = s.decode
    assert d.len == HdrTotalLen
    for _ in 0..1:
      for _ in 0..2:
        q.add(d.show(n, SessKeyLen))
        n.inc(SessKeyLen)
      q.add(d.show(n, NonceLenH))
      n.inc(NonceLenH)
    result = q.join("\n")

  proc ppSk(k: SessKey): string =
    k.mapIt(it.int.toHex(2)).join(" ")

  proc ppSk(a: openArray[SessKey]): seq[string] =
    result = newSeq[string](a.len)
    for n in 0..<a.len:
      result[n] = a[n].ppSk

  block:
    var
      pk: array[3, EccPrvKey]
      pu: array[3, EccPubKey]
      kp: array[3,ptr EccPrvKey]
      ku: array[3,ptr EccPubKey]
    for n in 0..2:
      pk[n].getEccPrvKey()
      kp[n] = addr pk[n]
      pu[n].getEccPubKey(kp[n])
      ku[n] = addr pu[n]
    var
      msg: SessKey
      msa: array[3,SessKey]
      hdr = getB64SessHeader(msg, addr ku)
      key = msg.mapIt(it.ord.toHex(2)).join(" ")
    msa.extrB64SessMsg(hdr, addr kp)
    var
      kq  = msa.ppSk

    when not defined(check_run) and false:
      echo ">>>\n", hdr, "\n<<<"

    when not defined(check_run) and false:
      echo ">>> ", hdr.ppHdr.replace("\n", "\n    ")
      echo "    key: ", key
      echo ">>>      ", kq.join("\n         ")

    doAssert key == kq[0]
    doAssert key == kq[1]
    doAssert key == kq[2]

#  when not defined(check_run):
#    echo "*** not yet"

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
