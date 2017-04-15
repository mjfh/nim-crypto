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
  base64, rnd64, sequtils, strutils, uecc/uecc

const
  InLinelen  = 57
  OutLineLen = 76
  KeyHdrLen  = 2 * InLinelen

assert 57 * 4 == 76 * 3       # verify full base64 line width

type
  EccAnyKey = tuple
    key: UEccScalar

  EccPrvKey* = tuple
    prvKey: UEccScalar

  EccPubKey* = tuple
    pubKey: UEccScalar

  EccSessKey* = tuple
    sesKey: UEccScalar

# ----------------------------------------------------------------------------
# Private helpers
# ----------------------------------------------------------------------------

proc getRndData(): UEccScalar {.inline.} =
  for n, w in rnd8items(32):
    result[n] = w.uint8

proc getRndData(key: var UEccScalar) {.inline.} =
  for n, w in rnd8items(32):
    key[n] = w.uint8

proc pp(a: EccAnyKey; pfx, delim: string): string =
  ## pretty print key (for debugging)
  const
    st = "0x"
    dl = "u8," & st
  ("(" & pfx & "Key: [" &
    st & a.key[ 0..7 ].mapIt(it.int.toHex(2)).join(dl) & "," & delim &
    st & a.key[ 8..15].mapIt(it.int.toHex(2)).join(dl) & "," & delim &
    st & a.key[16..23].mapIt(it.int.toHex(2)).join(dl) & "," & delim &
    st & a.key[24..31].mapIt(it.int.toHex(2)).join(dl) &
   "])")

proc `$`(a: EccAnyKey): string =
  result = newString(a.key.len)
  for n in 0..<a.key.len:
    result[n] = a.key[n].chr

proc `$`(prv: EccPrvKey; delim: string = ""): string {.inline.} =
  ## convert to (binary) string format
  $cast[EccAnyKey](prv)

# ----------------------------------------------------------------------------
# Public functions
# ----------------------------------------------------------------------------

proc getEccPrvKey*(prv: var EccPrvKey) =
  ## create a new private key
  getRndData(prv.prvKey)
  prv.prvKey.uEccSanitise

proc getEccPubKey*(pub: var EccPubKey; prv: ptr EccPrvKey) =
  ## derive public key from private key
  pub.pubKey.uEccPubKey(addr prv.prvKey)

proc getEccSessKey*(resKey: var EccSessKey;
                    ownPrv: ptr EccPrvKey; dstPub: ptr EccPubKey) =
  ## derive session keq from own private key and destination public key
  resKey.sesKey.uEccSessionKey(addr ownPrv.prvKey, addr dstPub.pubKey)

proc getEccPreamble(pub1, pub2, pub3: EccPubKey): string = # {.deprecated.} =
  ## create destination headers for two destination streams; this function
  ## is deprecated and used for testing only, use sesskey.getSessHeader()
  ## instead
  var q: array[KeyHdrLen,uint8]
  assert 3 * 32 <= KeyHdrLen
  for n in 0..31:
    q[n     ] = pub1.pubKey[n].uint8
    q[n + 32] = pub2.pubKey[n].uint8
    q[n + 64] = pub3.pubKey[n].uint8
  const offs = 96
  for n, w in rnd8items(KeyHdrLen - offs):
    q[n + offs] = w.uint8
  result = q.encode

proc getEccPreamble(pub: EccPubKey): string = # {.deprecated.} =
  ## create destination headers for one destination stream; this function
  ## is deprecated and used for testing only, use sesskey.getSessHeader()
  ## instead
  var q: array[KeyHdrLen,uint8]
  assert 3 * 32 <= KeyHdrLen
  for n, w in rnd8items(32):
    q[n     ] = pub.pubKey[n].uint8
    q[n + 32] = w.uint8
  const offs = 64
  for n, w in rnd8items(KeyHdrLen - offs):
    q[n + offs] = w.uint8
  result = q.encode

proc getEccPubKey(preamble: string):
                 (EccPubKey, EccPubKey, EccPubKey) = # {.deprecated.}=
  ## extract public key from destination stream header, may return nil on
  ## error; this function is deprecated and used for testing only, use
  ## sesskey.getSessHeader() instead
  var a = preamble.decode
  if 96 < a.len:
    for n in 0..31:
      result[0].pubKey[n] = a[n     ].uint8
      result[1].pubKey[n] = a[n + 32].uint8
      result[2].pubKey[n] = a[n + 64].uint8

proc pp*(prv: EccPrvKey; delim: string = ""): string {.inline.} =
  ## pretty print key (for debugging)
  pp(cast[EccAnyKey](prv), "prv", delim)

proc pp*(pub: EccPubKey; delim: string = ""): string {.inline.} =
  ## pretty print key (for debugging)
  pp(cast[EccAnyKey](pub), "pub", delim)

proc pp*(ses: EccSessKey; delim: string = ""): string {.inline.} =
  ## pretty print key (for debugging)
  pp(cast[EccAnyKey](ses), "ses", delim)

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:

  rnd64init(123)

  proc qq(s: string): string =
    s.replace("0x","")
     .replace("u8","")
     .replace(","," ")
     .replace("[","")
     .replace("]","")
     .replace("Key","")

  proc bb(s: string; indent = 6): string =
    s.replace("\l", "\l" & (" ".repeat(indent)))

  block:
    var
      kp0, kp1, kp2: EccPrvKey
      ku0, ku1, ku2: EccPubKey
      ss0, ss1, ss2: EccSessKey

    kp0.getEccPrvKey()
    kp1.getEccPrvKey()
    kp2.getEccPrvKey()
    ku0.getEccPubKey(addr kp0)
    ku1.getEccPubKey(addr kp1)
    ku2.getEccPubKey(addr kp2)

    getEccSessKey(ss0, addr kp0, addr ku1)
    getEccSessKey(ss1, addr kp1, addr ku0)
    getEccSessKey(ss2, addr kp2, addr ku1)

    when not defined(check_run) and false:
      echo ">>> 0 ", kp0.pp.qq
      echo "      ", ku0.pp.qq
      echo "      ", ss0.pp.qq
      echo ">>> 1 ", kp1.pp.qq
      echo "      ", ku1.pp.qq
      echo "      ", ss1.pp.qq
      echo ">>> 2 ", kp2.pp.qq
      echo "      ", ku2.pp.qq
      echo "      ", ss2.pp.qq
    doAssert ss0.pp.qq == ss1.pp.qq

    when not defined(check_run) and false:
      echo ">>> 0 ", getEccPreamble(ku0          ).bb
      echo ">>> 1 ", getEccPreamble(     ku1     ).bb
      echo ">>> 2 ", getEccPreamble(          ku2).bb
      echo ">>> x ", getEccPreamble(ku0, ku1, ku2).bb

    var
      xx0  = getEccPreamble(ku0          ).getEccPubKey
      xx1  = getEccPreamble(     ku1     ).getEccPubKey
      xx2  = getEccPreamble(          ku2).getEccPubKey
      xxx  = getEccPreamble(ku0, ku1, ku2).getEccPubKey

    when not defined(check_run) and false:
      echo ">>> 0 ", xx0[0].pp.qq
      echo "      ", xx0[1].pp.qq
      echo "      ", xx0[2].pp.qq
      echo ">>> 1 ", xx1[0].pp.qq
      echo "      ", xx1[1].pp.qq
      echo "      ", xx1[2].pp.qq
      echo ">>> x ", xxx[0].pp.qq
      echo "      ", xxx[1].pp.qq
      echo "      ", xxx[2].pp.qq

    doAssert xx0[0].pp.qq == ku0.pp.qq
    doAssert xx1[0].pp.qq == ku1.pp.qq
    doAssert xx2[0].pp.qq == ku2.pp.qq
    doAssert xxx[0].pp.qq == ku0.pp.qq
    doAssert xxx[1].pp.qq == ku1.pp.qq
    doAssert xxx[2].pp.qq == ku2.pp.qq

#  when not defined(check_run):
#    echo "*** not yet"

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
