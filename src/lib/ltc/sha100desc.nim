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

type
  Sha100Data* = array[32, uint8]
  Sha100State* = tuple
    length: uint64
    state:  array[8, uint32]
    curlen: uint32
    buf:    array[64, uint8]

# ----------------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------------

when isMainModule:

  import
    misc / [prjcfg]

  type
    HashState = tuple
      sha: Sha100State
      
  {.passC: " -I " & "headers".nimSrcDirname.}

  var
    p: HashState
    a = cast[int](addr p)
    varSha256Length {.
      importc: "offsetof(hash_state, sha256.length)",
      header: "tomcrypt.h".}: int
    varSha256State {.
      importc: "offsetof(hash_state, sha256.state)",
      header: "tomcrypt.h".}: int
    varSha256Curlen {.
      importc: "offsetof(hash_state, sha256.curlen)",
      header: "tomcrypt.h".}: int
    varSha256Buf {.
      importc: "offsetof(hash_state, sha256.buf)",
      header: "tomcrypt.h".}: int
    varSha256StateSizeof {.
      importc: "sizeof(struct sha256_state)",
      header: "tomcrypt.h".}: int
    varSha256HashStateSizeof {.
      importc: "sizeof(hash_state)",
      header: "tomcrypt.h".}: int
  doAssert varSha256Length          == (cast[int](addr p.sha.length) - a)
  doAssert varSha256State           == (cast[int](addr p.sha.state)  - a)
  doAssert varSha256Curlen          == (cast[int](addr p.sha.curlen) - a)
  doAssert varSha256Buf             == (cast[int](addr p.sha.buf)    - a)
  doAssert varSha256StateSizeof     == p.sha.sizeof
  doAssert varSha256HashStateSizeof == p.sizeof
    
# ----------------------------------------------------------------------------
# End
# ----------------------------------------------------------------------------
