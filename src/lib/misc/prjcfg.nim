# -*- nim -*-
#
# $Id$
#
# -- Jordan Hrycaj <jordan@mjh-it.com>

import
  algorithm, os, sequtils, strutils, misc / [seqext]

export
  algorithm, os, sequtils, strutils, seqext

when defined(ignNimPaths):
  const
    # source root subdirectoy containing NIM sources, this must be a
    # directory parent/ancestor of this NIM source
    sourceDir = "src"
else:
  include misc/nim_paths_inc

type # handy defs
  SiUnit* = enum
    KiB= 1024,
    MiB = KiB.ord * KiB.ord,
    GiB = KiB.ord * MiB.ord,

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
  const d = nimSrcDirSep()
  when defined(ignNimPaths):
    # walk backwards until sourceDir is found
    const
      base  = sourceDir.split(d).head[0]
      dirs  = nimSrcDirname().split(d)
    for n in 0 .. <dirs.len:
      if dirs[n] == base:
        result = dirs[0 .. <n].join($d)
        break
  else:
    result = prjRootDir.replace("/", $d)

proc nimSrcRoot*(relPosixPath: string): string {.compileTime.} =
  ## prepend relaive posix path by source root
  const d = nimSrcDirSep()
  nimSrcRoot() & d & relPosixPath.replace("/", $d)

proc cnfTable*(): seq[(string,string)] {.compileTime.} =
  ## assignment-value pair table generated from autoconfig header file
  when defined(ignNimPaths):
    result = @[]
  else:
    var
      p = nimSrcRoot()
      d = p[2 * (p[1] == ':').ord]
      s = slurp prjConfFileH.replace(DirSep,d)
    return s.split({'\c','\l'})
      .filter(proc(s: string): bool = s.len > 9 and s[0..7] == "#define ")
      .mapIt(seq[string], it.split(maxsplit = 3)[1..2])
      .mapIt((string,string), (it[0], it[1].strip(chars = {'"','\''})))

proc cnfValue*(s: string): string {.compileTime.} =
  ## particular value lookup from autoconfig header file
  (cnfTable().concat(@[(s,"")]).filterIt(it[0] == s).head)[0][1]

proc cnfValue*(s: string; default: string): string {.compileTime.} =
  result = s.cnfValue
  if result == "":
    result = default

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:

  const
    cfgTable = cnfTable().mapIt(string, it[0] & ": " & it[1]).join("\n")
    pkgName  = "PACKAGE_NAME"

  when not defined(check_run):
    echo "*** ", pkgName, "=", cnfValue(pkgName)
    echo "** full table:\n", cfgTable, "\n"
    when defined(ignNimPaths):
      echo "*** sourceDir=", sourceDir, " autoConfFileH=", autoConfFileH
    else:
      echo "*** prjRootDir=", prjRootDir
      echo "    prjConfFileH=", prjConfFileH

  doAssert cnfValue(pkgName).len > 0
  doAssert cnfValue("*") == ""
  doAssert nimSrcBasename() == "prjcfg"

# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
