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
  ltc / [aes80desc, ltc_const, sha100desc]

export
  aes80desc, sha100desc

# ----------------------------------------------------------------------------
# Public
# ----------------------------------------------------------------------------

type
  FrtaPools* = array[ltcFrtaPools,Sha100State]
  Frta* = tuple
    pool:   FrtaPools              # the pools
    sKey:   Aes80Key
    K:      array[32,int8]         # the current key
    IV:     array[16,int8]         # IV for CTR mode
    pIdx:   culong                 # current pool we will add to
    p0Len:  culong                 # length of 0'th pool
    wd:     culong
    resCnt: uint64                 # number of times we have reset

  FrtaEntropy* = array[32*ltcFrtaPools,int8]

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:

  import
    misc / [prjcfg]

  type
    PrngState = tuple
      frta: Frta

  {.passC: " -I " & "headers".nimSrcDirname.}

  var
    p: PrngState
    a = cast[int](addr p)
    varFrtaPool {.
      importc: "offsetof(prng_state, fortuna.pool)",
      header: "tomcrypt.h".}: int
    varFrtaPoolInx1 {.
      importc: "offsetof(prng_state, fortuna.pool[1])",
      header: "tomcrypt.h".}: int
    varFrtaSkey {.
      importc: "offsetof(prng_state, fortuna.skey)",
      header: "tomcrypt.h".}: int
    varFrtaK {.
      importc: "offsetof(prng_state, fortuna.K)",
      header: "tomcrypt.h".}: int
    varFrtaIV {.
      importc: "offsetof(prng_state, fortuna.IV)",
      header: "tomcrypt.h".}: int
    varFrtaPoolIdx {.
      importc: "offsetof(prng_state, fortuna.pool_idx)",
      header: "tomcrypt.h".}: int
    varFrtaPool0Len {.
      importc: "offsetof(prng_state, fortuna.pool0_len)",
      header: "tomcrypt.h".}: int
    varFrtaWd {.
      importc: "offsetof(prng_state, fortuna.wd)",
      header: "tomcrypt.h".}: int
    varFrtaResetCnt {.
      importc: "offsetof(prng_state, fortuna.reset_cnt)",
      header: "tomcrypt.h".}: int
    varFrtaSizeof {.
      importc: "sizeof(struct fortuna_prng)",
      header: "tomcrypt.h".}: int
    varPrngStateSizeof {.
      importc: "sizeof(prng_state)",
      header: "tomcrypt.h".}: int
  doAssert varFrtaPool        == (cast[int](addr p.frta.pool)    - a)
  doAssert varFrtaPoolInx1    == (cast[int](addr p.frta.pool[1]) - a)
  doAssert varFrtaSkey        == (cast[int](addr p.frta.sKey)    - a)
  doAssert varFrtaK           == (cast[int](addr p.frta.K)       - a)
  doAssert varFrtaIV          == (cast[int](addr p.frta.IV)      - a)
  doAssert varFrtaPoolIdx     == (cast[int](addr p.frta.pIdx)    - a)
  doAssert varFrtaPool0Len    == (cast[int](addr p.frta.p0Len)   - a)
  doAssert varFrtaWd          == (cast[int](addr p.frta.wd)      - a)
  doAssert varFrtaResetCnt    == (cast[int](addr p.frta.resCnt)  - a)
  doAssert varFrtaSizeof      == (p.frta.sizeof)
  doAssert varPrngStateSizeof == (p.sizeof)

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
