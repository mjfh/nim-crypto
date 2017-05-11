# -*- nim -*-
#
# micro ECC library wrapper
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
  misc / [prjcfg],
  uecc / [ueccdesc]

export
  ueccdesc

# ----------------------------------------------------------------------------
# Uecc compiler
# ----------------------------------------------------------------------------

proc ueccPath(s: string = nil): string {.compileTime.} =
  var w =  if s.isNil: "" else: "/" & s
  result = (UeccSrcDir & w).nimSrcDirname

const
  ueccHeader = "include/libuecc/ecc.h".ueccPath

{.passC: "-I " & "include".ueccPath.}
{.compile: "src/ec25519.c"    .ueccPath.}
{.compile: "src/ec25519_gf.c" .ueccPath.}

# ----------------------------------------------------------------------------
# Uecc library interface
# ----------------------------------------------------------------------------

# EC group operations for Twisted Edwards Curve
#
#    ax^2 + y^2 = 1 + dx^2y^2
#
# on prime field p = 2^{255} - 19.
#
# Two different (isomorphic) sets of curve parameters are supported:
#
#   a = 486664 and d = 486660
#
# are the parameters used by the original libuecc implementation (till v5).
# To use points on this curve, use the functions with the suffix legacy.
#
# The other supported curve uses the parameters
#
#   a = -1 and d = -(121665/121666),
#
# which is the curve used by the Ed25519 algorithm. The functions for this
# curve have the suffix ed25519.
#
# Internally, libuecc always uses the latter representation for its work
# structure.
#
# The curves are equivalent to the Montgomery Curve used in D. J. Bernstein's
# Curve25519 Diffie-Hellman algorithm.
#
# See http://hyperelliptic.org/EFD/g1p/auto-twisted-extended.html for add and
# double operations.


# Loads a point of the Ed25519 curve with given coordinates into its
# unpacked representation
#
# Params:
#   u -- Output
#   x -- Input, coordinate
#   y -- Input, coordinate
#
proc ecc_25519_load_xy_ed25519*(u: ptr UEccWorker;
                                x: ptr UEccScalar;
                                y: ptr UEccScalar): cint
  {.cdecl, header: ueccHeader, importc.}



# Stores the x and y coordinates of a point of the Ed25519 curve
#
# Params:
#    x -- Returns the x coordinate of the point. May be NULL.
#    y -- Returns the y coordinate of the point. May be NULL.
#    w -- Input, the unpacked point to store.
#
proc ecc_25519_store_xy_ed25519*(x: ptr UEccScalar;
                                 y: ptr UEccScalar;
                                 w: ptr UEccWorker)
  {.cdecl, header: ueccHeader, importc.}


# Loads a packed point of the Ed25519 curve into its unpacked representation
#
# The packed format is different from the legacy one: the legacy format
# contains that X coordinate and the parity of the Y coordinate,
# Ed25519 uses the Y coordinate and the parity of the X coordinate.
#
# Params:
#   u -- Output
#   n -- Input, scalar
# Rerurn:
#   1 -- ok (otherwise 0)
#
proc ecc_25519_load_packed_ed25519*(u: ptr UEccWorker;
                                    n: ptr UEccScalar): cint
  {.cdecl, header: ueccHeader, importc.}


# Stores a point of the Ed25519 curve into its packed representation
#
# The packed format is different from the Ed25519 one: the legacy format
# contains that X coordinate and the parity of the Y coordinate,
# Ed25519 uses the Y coordinate and the parity of the X coordinate.
#
# Params:
#   u -- Output
#   w -- Input
#
proc ecc_25519_store_packed_ed25519*(u: ptr UEccScalar;
                                     w: ptr UEccWorker)
  {.cdecl, header: ueccHeader, importc.}


# Stores a point of the legacy curve into its packed representation
#
# New software should use \ref ecc_25519_store_packed_ed25519, which uses
# the same curve and packed representation as the Ed25519 algorithm.
#
# The packed format is different from the Ed25519 one: the legacy format
# contains that X coordinate and the parity of the Y coordinate,
# Ed25519 uses the Y coordinate and the parity of the X coordinate.
#
# Params:
#   u -- Output
#   w -- Input
#
proc ecc_25519_store_packed_legacy*(u: ptr UEccScalar;
                                    w: ptr UEccWorker)
  {.cdecl, header: ueccHeader, importc.}


# Checks if a point is the identity element of the Elliptic Curve group
#
# Params:
#   w -- Input
#
proc ecc_25519_is_identity*(w: ptr UEccWorker): cint
  {.cdecl, header: ueccHeader, importc: "ecc_25519_is_identity".}


# Negates a point of the Elliptic Curve
#
# The same pointer may be given for input and output
#
# Params:
#   u -- Output
#   w -- Input
#
proc ecc_25519_negate*(u: ptr UEccWorker;
                       w: ptr UEccWorker)
  {.cdecl, header: ueccHeader, importc.}


# Doubles a point of the Elliptic Curve
#
# ecc_25519_double(out,in) is equivalent to ecc_25519_add(out,in,in), but
# faster.
#
#  The same pointer may be given for input and output.
#
proc ecc_25519_double*(u: ptr UEccWorker;
                       w: ptr UEccWorker)
  {.cdecl, header: ueccHeader, importc.}


# Adds two points of the Elliptic Curve
#
# The same pointers may be given for input and output.
#
# Params:
#   u -- Output
#   v -- Input
#   w -- Input
#
proc ecc_25519_add*(u: ptr UEccWorker;
                    v: ptr UEccWorker;
                    w: ptr UEccWorker)
  {.cdecl, header: ueccHeader, importc: "ecc_25519_add".}


# Subtracts two points of the Elliptic Curve
#
# The same pointers may be given for input and output.
#
# Params:
#   u -- Output
#   v -- Input
#   w -- Input
#
proc ecc_25519_sub*(u: ptr UEccWorker;
                    v: ptr UEccWorker;
                    w: ptr UEccWorker)
  {.cdecl, header: ueccHeader, importc.}


# Does a scalar multiplication of a point of the Elliptic Curve with an
# integer of a given bit length
#
# To speed up scalar multiplication when it is known that not the whole 256
# bits of the scalar are used. The bit length should always be a constant
# and not computed at runtime to ensure that no timing attacks are possible.
#
# The same pointer may be given for input and output.
#
# Params:
#   u -- Output
#   n -- Input, scalar
#   g -- Input, base/generator
#   b -- #bits for n
#
proc ecc_25519_scalarmult_bits*(u: ptr UEccWorker;
                                n: ptr UEccScalar;
                                g: ptr UEccWorker;
                                b: cuint)
  {.cdecl, header: ueccHeader, importc.}


# Does a scalar multiplication of a point of the Elliptic Curve with
# an integer
#
# The same pointer may be given for input and output.
#
# Params:
#   u -- Output
#   n -- Input, scalar
#   p -- Input, point
#
proc ecc_25519_scalarmult*(u: ptr UEccWorker;
                           n: ptr UEccScalar;
                           p: ptr UEccWorker)
  {.cdecl, header: ueccHeader, importc.}


# Does a scalar multiplication of the default base point (generator element)
# of the Elliptic Curve with an integer of a given bit length
#
# The order of the base point is
#            2^{252} + 27742317777372353535851937790883648493.
#
# ecc_25519_scalarmult_base_bits(out,n,bits) is faster than
# ecc_25519_scalarmult_bits(out,n,&ecc_25519_work_default_base, bits).
#
# See the notes about 'ecc_25519_scalarmult_bits' before using this function.
#
# Params:
#   u -- Output
#   n -- Input, scalar
#   b -- #bits for n
#
proc ecc_25519_scalarmult_base_bits*(u: ptr UEccWorker;
                                     n: ptr UEccScalar;
                                     b: cuint)
  {.cdecl, header: ueccHeader, importc.}


# Does a scalar multiplication of the default base point (generator element)
# of the Elliptic Curve with an integer
#
# The order of the base point is
#         2^{252} + 27742317777372353535851937790883648493
#
# ecc_25519_scalarmult_base(out, n) is faster than
# ecc_25519_scalarmult(out, n, &ecc_25519_work_default_base).
#
# Params:
#   u -- Output
#   n -- Input, scalar
#
proc ecc_25519_scalarmult_base*(u: ptr UEccWorker;
                                n: ptr UEccScalar)
  {.cdecl, header: ueccHeader, importc.}

# ----------------------------------------------------
# gf_ops Prime field operations for the order of the
# base point of the Elliptic Curve
# ----------------------------------------------------

# Checks if an integer is equal to zero (after reduction)
#
# Params:
#   n -- Input, scalar
#
proc ecc_25519_gf_is_zero*(n: ptr UEccScalar): cint
  {.cdecl, header: ueccHeader, importc.}


# Adds two integers as Galois field elements
#
# The same pointers may be given for input and output.
#
# Params:
#   u -- Output
#   n -- Input, scalar
#   m -- Input, scalar
#
proc ecc_25519_gf_add*(u: ptr UEccScalar;
                       n: ptr UEccScalar;
                       m: ptr UEccScalar)
  {.cdecl, header: ueccHeader, importc: "ecc_25519_gf_add".}


#  Subtracts two integers as Galois field elements
#
#  The same pointers may be given for input and output.
#
# Params:
#   u -- Output
#   n -- Input, scalar
#   m -- Input, scalar
#
proc ecc_25519_gf_sub*(u: ptr UEccScalar;
                       n: ptr UEccScalar;
                       m: ptr UEccScalar)
  {.cdecl, header: ueccHeader, importc.}


# Reduces an integer to a unique representation in the range [0,q-1]
#
# The same pointer may be given for input and output.
#
# Params:
#   u -- Output
#   n -- Input, scalar
#
proc ecc_25519_gf_reduce*(u: ptr UEccScalar;
                          n: ptr UEccScalar)
  {.cdecl, header: ueccHeader, importc.}


# Multiplies two integers as Galois field elements
#
# The same pointers may be given for input and output.
#
# Params:
#   u -- Output
#   n -- Input, scalar
#   m -- Input, scalar
#
proc ecc_25519_gf_mult*(u: ptr UEccScalar;
                        n: ptr UEccScalar;
                        m: ptr UEccScalar)
  {.cdecl, header: ueccHeader, importc.}


# Computes the reciprocal of a Galois field element
#
# The same pointers may be given for input and output.
#
# Params:
#   u -- Output
#   n -- Input, scalar
#
proc ecc_25519_gf_recip*(u: ptr UEccScalar;
                         n: ptr UEccScalar)
  {.cdecl, header: ueccHeader, importc.}


# Ensures some properties of a Galois field element to make it fit for use
# as a secret key
#
#  This sets the 255th bit and clears the 256th and the bottom three bits
# (so the key will be a multiple of 8). See Daniel J. Bernsteins paper
# "Curve25519: new Diffie-Hellman speed records." for the rationale of this.
#
#  The same pointer may be given for input and output.
#
# Params:
#   u -- Output
#   n -- Input, scalar
#
proc ecc_25519_gf_sanitize_secret*(u: ptr UEccScalar;
                                   n: ptr UEccScalar)
  {.cdecl, header: ueccHeader, importc.}

# ----------------------------------------------------------------------------
# Public interface
# ----------------------------------------------------------------------------

## For an explanation how it works see
##   //en.wikipedia.org/wiki/Elliptic_curve_Diffie-Hellman

proc uEccSanitise*(d: var UEccScalar) {.inline.} =
  ## sanitise secret d ready for use as secret key
  # var dPtr = cast[ptr UEccScalar](addr d[0])
  ecc_25519_gf_sanitize_secret(addr d, addr d)


proc uEccPubKey*(X: var UEccScalar;
                 d: ptr UEccScalar) {.inline.} =
  ## given secret d, return public key Q = d*G, Q is in packed format
  var wObj: UEccWorker
  ecc_25519_scalarmult_base(addr wObj, d)
  ecc_25519_store_packed_ed25519(addr X, addr wObj)
  (addr wObj).zeroMem(wObj.sizeof)


proc uEccSessionKey*(X: var UEccScalar;
                     d: ptr UEccScalar;
                     Q: ptr UEccScalar): bool {.discardable,inline.} =
  ## given secret d and another public key Q (in packed format), set X
  ## as session key in packed format
  var
    wObj: UEccWorker
    nOk  = ecc_25519_load_packed_ed25519(addr wObj, Q)         # expand Q
  if nOk == 1:
    result = true
    var y: UEccScalar
    ecc_25519_scalarmult(addr wObj, d, addr wObj)              # => d * Q
    ecc_25519_store_xy_ed25519(addr X, addr y, addr wObj) # compress
    (addr y).zeroMem(y.sizeof)
  (addr wObj).zeroMem(wObj.sizeof)

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:

  import base64

  proc toSeq(a: UEccScalar): seq[int8] =
    result = newSeq[int8](a.len)
    for n in 0..<a.len:
      result[n] = a[n].int.toU8

  proc pp(a: UEccScalar): string =
    a.toSeq.mapIt(it.toHex(2).toLowerAscii).join

  block:
    var d0, Q0: UEccScalar
    for n in 0..31: d0[n] = ('A'.ord + n).uint8
    d0.uEccSanitise
    Q0.uEccPubKey(addr d0)

    var d1, Q1: UEccScalar
    for n in 0..31: d1[n] = ('a'.ord + n).uint8
    d1.uEccSanitise
    Q1.uEccPubKey(addr d1)

    var k0, k1: UEccScalar
    k0.uEccSessionKey(addr d0, addr Q1)
    k1.uEccSessionKey(addr d1, addr Q0)

    when not defined(check_run) and false:
      discard
      echo ">> ", Q0.pp, " >> ", k0.pp
      echo ">> ", Q1.pp, " >> ", k1.pp
    assert k0 == k1

    var
      Q0e = encode Q0
      Q0d = decode Q0e
    when not defined(check_run):
      discard
      echo ">> b64=", Q0e
      echo ">> rev=", Q0d.mapIt(it.ord.toHex(2).toLowerAscii).join(" ")
      echo ">> b64=", encode Q1

#  when not defined(check_run):
#    echo "*** not yet"

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
