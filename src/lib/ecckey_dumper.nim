# -*- nim -*-
#
# generate file with public/private key pair for NIM import
#
# $Id: e36fef0e79b794b79079e2f1020d0d30d34f20da $
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

import
  ecckey, os, parseopt, rnd64, streams, strutils, times

# ----------------------------------------------------------------------------
# MAIN
# ----------------------------------------------------------------------------

proc stdhp*(oStm = stdout; eStm = stderr;
            inPfx: string = nil; extra = "") =

  proc usage() =
    write eStm, "\nUsage: escrow_dumper <pfx>\n\n"
    quit "STOP"

  var
    pfx = ""

  for kind, key, val in getopt():
    case kind
    of cmdArgument:
      pfx = key
    else:
      usage()

  if not inPfx.isNil:
    pfx = inPfx
  elif pfx == "":
    usage()

  # make sure seeds differ even when called within same minute
  rnd64init(pfx, epochTime())

  var
    prv: EccPrvKey
    pub: EccPubKey
    dlm = "\n" & " ".repeat(14)

  prv.getEccPrvKey()
  pub.getEccPubKey(addr prv)

  write oStm, "# ECC key details:\n"
  write oStm, "#   Date:   " & $getTime() & "\n"
  write oStm, "#   Prefix: '" & $pfx & "'\n\n"

  if extra.len != 0:
    writeLine oStm, extra

  write oStm, "import\n"
  write oStm, "  ecckey\n"
  write oStm, "export\n"
  write oStm, "  ecckey\n\n"

  write oStm, "const\n"
  write oStm, "  "   & pfx & "PrvKey: EccPrvKey =\n"
  write oStm, "    " & prv.pp(dlm) & "\n\n"

  write oStm, "  "   & pfx & "PubKey*: EccPubKey =\n"
  write oStm, "    " & pub.pp(dlm) & "\n\n"

  write oStm, "# End ECC key\n"

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:
  when not defined(check_run):
    stdhp(inPfx = "eccTest")

#----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
