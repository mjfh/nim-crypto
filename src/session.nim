# -*- nim -*-
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
# Provide C interface => libsession.a
#
# Compile:
#    crylib=..
#    nim c -p:$crylib --app:staticLib --noMain --header session.nim
#

import
  xcrypt

# ----------------------------------------------------------------------------
# Private functions
# ----------------------------------------------------------------------------

proc doB64Encrypt(s: string; pub: ptr EccPubKey): string =
  var
    ctx: XCryptCtx
    keys = [pub, nil, nil]
    chl  = getXVerfier()
  result = ctx.getXB64Encrypt(addr keys, addr chl) &
           ctx.xB64Encrypt(s)
  ctx.clearXCrypt

proc doB64Decrypt(s: string; prv: ptr EccPrvKey): string =
  var
    ctx: XCryptCtx
    chl = getXVerfier()
    pre = ctx.getXB64Decrypt(s, prv, addr chl)
  doAssert 0 < pre
  result = ctx.xB64Decrypt(s[pre..<s.len])
  ctx.clearXCrypt

# ----------------------------------------------------------------------------
# Public functions
# ----------------------------------------------------------------------------

proc b64_encrypt*(s: cstring; pub: pointer): cstring {.exportc.} =
  doB64Encrypt($s, cast[ptr EccPubKey](pub))

proc b64_decrypt*(s: cstring; prv: pointer): cstring {.exportc.} =
  doB64Decrypt($s, cast[ptr EccPrvKey](prv))

proc prvkey*: pointer {.exportc.} =
  var prvKey: EccPrvKey
  prvKey.getEccPrvKey
  result = alloc(sizeof EccPrvKey)
  result.copyMem(addr prvKey, sizeof EccPrvKey)

proc pubkey*(prvKey: pointer): pointer {.exportc.} =
  var
    pubKey: EccPubKey
    prvKeyPtr = cast[ptr EccPrvKey](prvKey)
  pubKey.getEccPubKey(prvKeyPtr)
  result = alloc(sizeof EccPubKey)
  result.copyMem(addr pubKey, sizeof EccPubKey)

proc freekey*(key: pointer) {.exportc.} =
  key.dealloc

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:

  proc pull_in_library =
    discard b64_encrypt(nil, nil)
    discard b64_decrypt(nil, nil)
    discard prvkey()
    discard pubkey(nil)
    freekey(nil)

  when not defined(check_run):
    echo "*** compiles OK"

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
