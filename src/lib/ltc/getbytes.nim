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
# Ackn:
#  inspired by libtomcrypt/src/prngs/rng_get_bytes.c
#
import
  sequtils, strutils,
  misc / prjcfg

type # for ANSI/clock() generator
  EntropyCallBack* = proc()

when defined(ignNimPaths):
  # just try them all
  const EnableRngNix  = true
  const EnableRngAnsi = true
  when defined(windows):
    const EnableRngWin = true
else:
  when "HAVE_DEV_RANDOM".cnfValue != "":
    const EnableRngNix = true
  when "STDC_HEADERS".cnfValue != "":
    const EnableRngAnsi = true
  when "_WINDOWS".cnfValue != "":
    const EnableRngWin = true

# ----------------------------------------------------------------------------
# Private: entropy from /dev/*random
# ----------------------------------------------------------------------------

when declared(EnableRngNix):
  discard EnableRngNix
  when not declared(EntropySourceOK):
    const EntropySourceOK = true

  import posix

  var IONBF {.importc: "_IONBF", header: "<stdio.h>".}: cint
  proc setvbuf(strm: File, buf: pointer, mode: cint, size: csize): cint {.
    importc, header: "<stdio.h>".}

  const
    DevRandom  = "DEV_RANDOM".cnfValue("/dev/random")
    DevURandom = "DEV_URANDOM".cnfValue("/dev/urandom")

  proc rngNix(buf: pointer; size: int): int {.inline.} =
    var
      rnd  = DevURandom.open
    if rnd.isNil:
      rnd =  DevRandom.open
    if not rnd.isNil:
      if rnd.setvbuf(nil, IONBF, 0) == 0: # disable buffering
        result = rnd.readBuffer(buf, size)
      rnd.close

# ----------------------------------------------------------------------------
# Private: entropy from clock() service
# ----------------------------------------------------------------------------

when declared(EnableRngAnsi):
  discard EnableRngAnsi
  when not declared(EntropySourceOK):
    const EntropySourceOK = true

  # works on MinGW as well
  import posix

  if isMainModule:
    # not available at compile time - trigger unit test failure
    if CLOCKS_PER_SEC < 100:
      quit "PANIC: Clock resolution is too low"

  let
    scaleDown = if 10000 < CLOCKS_PER_SEC:
                  (CLOCKS_PER_SEC * 100) div 1000000
                else:
                  1

  proc xclock: int =
    clock().int div scaleDown

  #when defined(testonly) and not defined(check_run):
  #  echo ">>> CLOCKS_PER_SEC=", CLOCKS_PER_SEC

  proc rngAnsiC(buf: pointer; size: int;
                cb: EntropyCallBack): int {.inline.} =
    var
      acc, a, b: int
      p = cast[ptr array[int.high,int8]](buf)

    while result < size:
      var bits = 8
      if not cb.isNil:
        cb()

      while 0 < bits:
        bits.dec
        assert a == 0 and b == 0

        while a == b:
          var t1 = xclock()
          while t1 == xclock():
            a = a xor 1
          var t2 = xclock()
          while t2 == xclock():
            b = b xor 1
        acc = (acc shl 1) or a
        a   = 0
        b   = 0

      p[result] = acc.toU8
      result.inc
      acc = 0

# ----------------------------------------------------------------------------
# Private: windows entropy generator (slow, like /dev/random)
# ----------------------------------------------------------------------------

when declared(EnableRngWin):
  discard EnableRngWin
  when not declared(EntropySourceOK):
    const EntropySourceOK = true

  {.compile: "getbytesd/wincrypt.c".nimSrcDirname.}
  proc rng_win32 (buf: pointer, size: culong): culong {.cdecl, importc.}

  proc rngWin(buf: pointer; size: int): int {.inline.} =
    rng_win32(buf, size.culong).int

# ----------------------------------------------------------------------------
# Private: Check for entropy source
# ----------------------------------------------------------------------------

when not declared(EntropySourceOK):
  {.error: "PANIC: Entropy source missing".}

discard EntropySourceOK

# ----------------------------------------------------------------------------
# Public interface
# ----------------------------------------------------------------------------

proc getBytes*(buf: pointer; size: int; cb: EntropyCallBack): int {.inline.} =
  ## Provide entropy and store it in the argument buffer. If cb() is
  ## not NIL it is applied to the AnsiC clock() entropy collector.
  block:
    when declared(EnableRngNix):
      when defined(testonly) and not defined(check_run):
        echo "*** getBytes: trying rngNix"
      result = buf.rngNix(size)
      if 0 < result:
        break
    when declared(EnableRngAnsi) and not defined(windows):
      when defined(testonly) and not defined(check_run):
        echo "*** getBytes: trying rngAnsiC (non-windows)"
      result = buf.rngAnsiC(size, cb)
      if 0 < result:
        break
    when declared(EnableRngWin):
      when defined(testonly) and not defined(check_run):
        echo "*** getBytes: trying rngWin"
      result = buf.rngWin(size)
      if 0 < result:
        break
    # poor performance on Windows/MinGW, so take this last
    when declared(EnableRngAnsi) and defined(windows):
      when defined(testonly) and not defined(check_run):
        echo "*** getBytes: trying rngAnsiC (windows)"
      result = buf.rngAnsiC(size, cb)
      if 0 < result:
        break

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:

  proc fromHexSeq(buf: seq[int8]; sep = " "): string =
    ## dump an array or a data sequence as hex string
    buf.mapIt(it.toHex(2).toLowerAscii).join(sep)

  proc fromHexSeq(s: string; sep = " "): string =
    var q = newSeq[int8](s.len)
    for n in 0..<s.len:
      q[n] = s[n].ord.int.toU8
    result = q.fromHexSeq(sep)

  when declared(EnableRngNix):
    block:
      var
        buf = newString(20)
        cnt = (addr buf[0]).rngNix(buf.len)
      when not defined(check_run):
        echo "*** rngNix enabled"
        echo ">>> ", cnt, " >> ", buf.fromHexSeq
      doAssert cnt == buf.len

  when declared(EnableRngAnsi):
    block:
      var helloWorldCount: int
      proc helloWorld =
        helloWorldCount.inc
      var
        buf = newString(20)
        cnt = (addr buf[0]).rngAnsiC(buf.len, helloWorld)
      when not defined(check_run):
        echo "*** rngAnsi enabled"
        echo ">>> ", helloWorldCount, " >> ", cnt, " >> ", buf.fromHexSeq
      doAssert helloWorldCount == buf.len and cnt == buf.len

  when declared(EnableRngWin):
    block:
      var
        buf = newString(20)
        cnt = (addr buf[0]).rngWin(buf.len)
      when not defined(check_run):
        echo "*** rngWin enabled"
        echo ">>> ", cnt, " >> ", buf.fromHexSeq
      doAssert cnt == buf.len

  block:
    var helloWorldCount: int
    proc helloWorld =
      helloWorldCount.inc
    var
      buf = newString(20)
      cnt = (addr buf[0]).getBytes(buf.len, helloWorld)
    when not defined(check_run):
      echo ">>> ", helloWorldCount, " >> ", cnt, " >> ", buf.fromHexSeq
    doAssert cnt == buf.len
    doAssert helloWorldCount == cnt or helloWorldCount == 0

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
