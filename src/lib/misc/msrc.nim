# -*- nim -*-
#
# $Id$
#
# -- Jordan Hrycaj <jordan@mjh-it.com>

import
  algorithm, os, sequtils, strutils

export
  algorithm, os, sequtils, strutils

const
  # source root subdirectoy containing NIM sources, this must be a
  # directory parent/ancestor of this NIM source
  sourceDir     = "src"

  # autoconfig header file relative to source root
  autoConfFileH = "conf" / "config.h"

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
# Public compile-time methods
# ----------------------------------------------------------------------------

template nimSrcFilename*(): string =
  ## filename of source importing this macro
  instantiationInfo(fullPaths=true).filename

template nimSrcBasename*(): string =
  ## basename of source importing this macro
  instantiationInfo()
    .filename.splitFile[1]
    .filterIt(it notin {'_','-'}) # ignore some chars
    .join

template nimSrcDirname*(): string =
  ## dirname of source importing this macro
  instantiationInfo(fullPaths=true)
    .filename.parentDir

proc nimSrcDirSep*(): char {.compileTime.} =
  const sPath = nimSrcDirname()               # starts with current DirSep ..
  result = sPath[2 * (sPath[1] == ':').ord]   # .. may differ from target

template nimSrcDirname*(relPosixPath: string): string =
  const
    d {.gensym.} = nimSrcDirSep()
    p {.gensym.} = instantiationInfo(fullPaths=true).filename.parentDir
  p & d & relPosixPath.replace("/", $d)

proc nimSrcRoot*(): string {.compileTime.} =
  ## installation base/root directory
  const
    d     = nimSrcDirSep()
    base  = sourceDir.split(d).head[0]
    dirs  = nimSrcDirname().split(d)
  for n in 0 .. <dirs.len:
    if dirs[n] == base:
      result = dirs[0 .. <n].join($d)
      break

proc nimSrcRoot*(relPosixPath: string): string {.compileTime.} =
  ## prepend relaive posix path by source root
  const d = nimSrcDirSep()
  nimSrcRoot() & d & relPosixPath.replace("/", $d)

proc cnfTable*(): seq[(string,string)] {.compileTime.} =
  ## assignment-value pair table generated from autoconfig header file
  var
    p = nimSrcRoot()
    d = p[2 * (p[1] == ':').ord]
    s = slurp p & $d & autoConfFileH.replace(DirSep,d)
  return s.split({'\c','\l'})
    .filter(proc(s: string): bool = s.len > 9 and s[0..7] == "#define ")
    .mapIt(seq[string], it.split(maxsplit = 3)[1..2])
    .mapIt((string,string), (it[0], it[1].strip(chars = {'"','\''})))

proc cnfValue*(s: string): string {.compileTime.} =
  ## particular value lookup from autoconfig header file
  (cnfTable().concat(@[(s,"")]).filterIt(it[0] == s).head)[0][1]

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:

  const
    cfgTable = cnfTable().mapIt(string, it[0] & ": " & it[1]).join("\n")
    pkgName  = "PACKAGE_NAME"

  when not defined(check_run):
    echo "*** ", pkgName, "=", cnfValue(pkgName)
    echo "** full table:\n", cfgTable, "\n."

  doAssert cnfValue(pkgName).len > 0
  doAssert cnfValue("*") == ""

  const
    basename  = nimSrcBasename()
    emptyHead = newSeq[int](0).head
    testHead  = [1, 2, 3, 4, 5].head
    emptyTail = newSeq[int](0).tail
    testTail  = [1, 2, 3, 4, 5].tail
    tes2Tail  = toSeq(1..5).tail

  doAssert basename  == "nimsrc"
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

#  when not defined(check_run):
#    echo "*** ", tes2Tail

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
