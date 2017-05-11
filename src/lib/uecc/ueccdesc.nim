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

# ----------------------------------------------------------------------------
# Public
# ----------------------------------------------------------------------------

const
  UeccSrcDir* = "private/uecc-v7"

type                                           # A 256 bit integer
  UEccScalar*  = array[32,uint8]               # renamed from ecc_int256_t
  UEccWorkRow* = array[32,cuint]               # part of UEccWorkT

  # A point on the curve unpacked for efficient calculation
  #
  # The internal representation of an unpacked point isn't unique, so for
  # serialization. It should always be packed.
  #
  UEccWorker* = tuple                          # renamed from ecc_25519_work_t
    X: UEccWorkRow
    Y: UEccWorkRow
    Z: UEccWorkRow
    T: UEccWorkRow

const
  workIdentityEasy =
    [[   0,    0,    0,    0,    0,    0,    0,    0,
         0,    0,    0,    0,    0,    0,    0,    0,
         0,    0,    0,    0,    0,    0,    0,    0,
         0,    0,    0,    0,    0,    0,    0,    0],
     [0x01,    0,    0,    0,    0,    0,    0,    0,
         0,    0,    0,    0,    0,    0,    0,    0,
         0,    0,    0,    0,    0,    0,    0,    0,
         0,    0,    0,    0,    0,    0,    0,    0],
     [0x01,    0,    0,    0,    0,    0,    0,    0,
         0,    0,    0,    0,    0,    0,    0,    0,
         0,    0,    0,    0,    0,    0,    0,    0,
         0,    0,    0,    0,    0,    0,    0,    0],
     [   0,    0,    0,    0,    0,    0,    0,    0,
         0,    0,    0,    0,    0,    0,    0,    0,
         0,    0,    0,    0,    0,    0,    0,    0,
         0,    0,    0,    0,    0,    0,    0,    0]]
  defaultBaseEasy =
    [[0x1a, 0xd5, 0x25, 0x8f, 0x60, 0x2d, 0x56, 0xc9,
      0xb2, 0xa7, 0x25, 0x95, 0x60, 0xc7, 0x2c, 0x69,
      0x5c, 0xdc, 0xd6, 0xfd, 0x31, 0xe2, 0xa4, 0xc0,
      0xfe, 0x53, 0x6e, 0xcd, 0xd3, 0x36, 0x69, 0x21],
     [0x58, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66,
      0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66,
      0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66,
      0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66],
     [0x01,    0,    0,    0,    0,    0,    0,    0,
         0,    0,    0,    0,    0,    0,    0,    0,
         0,    0,    0,    0,    0,    0,    0,    0,
         0,    0,    0,    0,    0,    0,    0,    0],
     [0xa3, 0xdd, 0xb7, 0xa5, 0xb3, 0x8a, 0xde, 0x6d,
      0xf5, 0x52, 0x51, 0x77, 0x80, 0x9f, 0xf0, 0x20,
      0x7d, 0xe3, 0xab, 0x64, 0x8e, 0x4e, 0xea, 0x66,
      0x65, 0x76, 0x8b, 0xd7, 0x0f, 0x5f, 0x87, 0x67]]
  gfOrderEasy =
    [0xed, 0xd3, 0xf5, 0x5c, 0x1a, 0x63, 0x12, 0x58,
     0xd6, 0x9c, 0xf7, 0xa2, 0xde, 0xf9, 0xde, 0x14,
        0,    0,    0,    0,    0,    0,    0,    0,
        0,    0,    0,    0,    0,    0,    0, 0x10]

proc toUEccWorker(a: array[4,array[32,int]]): UEccWorker {.compileTime.} =
  for i in 0..<a[0].len: result.X[i] = a[0][i].cuint
  for i in 0..<a[0].len: result.Y[i] = a[1][i].cuint
  for i in 0..<a[0].len: result.Z[i] = a[2][i].cuint
  for i in 0..<a[0].len: result.T[i] = a[3][i].cuint

proc toUEccScalar(a: array[32,int]): UEccScalar {.compileTime.} =
  for i in 0..<a.len: result[i] = a[i].uint8

const
  # Identity element
  eccWorkIdentity* = workIdentityEasy.toUEccWorker

  # The order of the base point is
  #       2^{252} + 27742317777372353535851937790883648493.
  eccWorkDefaultBase* = defaultBaseEasy.toUEccWorker

  # The order is 2^{252} + 27742317777372353535851937790883648493.
  eccGfOrder* = gfOrderEasy.toUEccScalar
    
# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:

  import
    misc / [prjcfg]

  proc ueccPath(s: string = nil): string {.compileTime.} =
    var w =  if s.isNil: "" else: "/" & s
    result = (UeccSrcDir & w).nimSrcDirname

  proc pp[T: UEccWorkRow|UEccScalar](a: T; sep = "\n"): string =
    proc ppx(n: cuint): string =
      if n == 0:
        "   0"
      else:
        "0x" & n.uint32.BiggestInt.toHex(2).toLowerAscii
    var q = a.len div 4
    result = "["
    for n in 0..3:
      if 0 < n:
        result &= "," & sep & " "
      result &= a[n*q].ppx
      for i in (n*q)+1..<(n+1)*q:
        result &= ", " & a[i].ppx
    result &= "]"
    
  proc pp(a: UEccWorker; sep = "\n"): string =
    ("[" & a.X.pp(sep) & "," & sep &
           a.Y.pp(sep) & "," & sep &
           a.Z.pp(sep) & "," & sep &
           a.T.pp(sep) & "]")

  import
    misc / [prjcfg]

  {.passC: " -I " & "include".ueccPath.}
  {.compile: "src/ec25519.c" .ueccPath.}
  {.compile: "src/ec25519_gf.c" .ueccPath.}

  # verify ECC constants
  var
    varEccWorkDefaultBase {.
      importc: "ecc_25519_work_default_base",
      header: "libuecc/ecc.h"}: UEccWorker
    varEccWorkIdentity {.
      importc: "ecc_25519_work_identity",
      header: "libuecc/ecc.h"}: UEccWorker
    varEccGfOrder {.
      importc: "ecc_25519_gf_order.p",
      header: "libuecc/ecc.h"}: UEccScalar
  # echo ">>> ", varEccWorkDefaultBase.pp("\n     ")
  # echo ">>> ", varEccGfOrder.pp("\n    ")
  doAssert varEccWorkDefaultBase == eccWorkDefaultBase
  doAssert varEccWorkIdentity    == eccWorkIdentity
  doAssert varEccGfOrder         == eccGfOrder

  # verify layout
  var
    p: UEccWorker
    a = cast[int](addr p)
    varUeccWorkerX {.
      importc: "offsetof(ecc_25519_work_t, X)",
      header: "libuecc/ecc.h".}: int
    varUeccWorkerY {.
      importc: "offsetof(ecc_25519_work_t, Y)",
      header: "libuecc/ecc.h".}: int
    varUeccWorkerZ {.
      importc: "offsetof(ecc_25519_work_t, Z)",
      header: "libuecc/ecc.h".}: int
    varUeccWorkerT {.
      importc: "offsetof(ecc_25519_work_t, T)",
      header: "libuecc/ecc.h".}: int
    varUeccWorkerSizeof {.
      importc: "sizeof(ecc_25519_work_t)",
      header: "libuecc/ecc.h".}: int
    varUeccScalarP {.
      importc: "offsetof(ecc_int256_t, p)",
      header: "libuecc/ecc.h".}: int
    varUeccScalarSizeof {.
      importc: "sizeof(ecc_int256_t)",
      header: "libuecc/ecc.h".}: int
  doAssert varUeccWorkerX      == (cast[int](addr p.X) - a)
  doAssert varUeccWorkerY      == (cast[int](addr p.Y) - a)
  doAssert varUeccWorkerZ      == (cast[int](addr p.Z) - a)
  doAssert varUeccWorkerT      == (cast[int](addr p.T) - a)
  doAssert varUeccWorkerSizeof == (sizeof(p))
  doAssert varUeccScalarP      == (0)
  doAssert varUeccScalarSizeof == (UEccScalar.sizeof)

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
