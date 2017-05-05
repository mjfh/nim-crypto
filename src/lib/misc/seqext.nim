# -*- nim -*-
#
# $Id$
#
# -- Jordan Hrycaj <jordan@mjh-it.com>

import
  sequtils

export
  sequtils

# ----------------------------------------------------------------------------
# Public methods for openArray/sequences
# ----------------------------------------------------------------------------

proc ifNil*[T](s: seq[T]; nilVal: T): seq[T] {.inline.} =
  if s.isNil: @[nilVal] else: s

proc tail*[T](s: seq[T]): seq[T] {.inline.} =
  ## => tail of a sequence (or empty sequence), optimised for seq[]
  if 0 < s.len: s[1..<s.len] else: @[]

proc tail*[T](s: openArray[T]): seq[T] {.inline.} =
  ## => tail of a sequence (or empty sequence) for general openArrays
  if 0 < s.len: (@s)[1..<s.len] else: @[]

proc head*[T](s: openArray[T]): seq[T] {.inline.} =
  ## => head of a sequence (or empty sequence)
  if 0 < s.len: @[s[0]] else: @[]

proc toOrdSet*[T](lst: varargs[T]): set[T] {.inline.} =
  ## map command-line arguments to ordinary sets (for HashSets see: toSet())
  for i in lst:
    result.incl(i)

proc toSetSeq*[T](s: set[T]): seq[T] =
  ## map ordinary set to sequence, result order is undefined
  result = newSeq[T](s.card)
  var n = 0
  for w in s:
    result[n] = w
    n.inc

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:

  const
    emptyHead = newSeq[int](0).head
    testHead  = [1, 2, 3, 4, 5].head
    emptyTail = newSeq[int](0).tail
    testTail  = [1, 2, 3, 4, 5].tail
    tes2Tail  = toSeq(1..5).tail

  doAssert emptyHead == @[]
  doAssert emptyTail == @[]
  doAssert testHead  == @[1]
  doAssert testTail  == @[2, 3, 4, 5]
  doAssert tes2Tail  == @[2, 3, 4, 5]

  type
    X0123 = enum
      XZero, XOne, XTwo, XThree
    Y01234 = enum
      YZero, YOne, YTwo, YThree, YFour

  const
    x02  = {XZero, XTwo}
    y02  = {YZero, YTwo}
    y024 = {YZero, YTwo, YFour}

    out1 =  x02.toSetSeq.mapIt(it.ord)
    out2 = y024.toSetSeq.mapIt(it.ord).filterIt(it <= X0123.high.ord)

  doAssert out1.mapIt(Y01234,Y01234(it)).toOrdSet == y02
  doAssert out2.mapIt( X0123, X0123(it)).toOrdSet == x02

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
