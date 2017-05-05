#ifndef TOMCRYPT_NIM_H_
#define TOMCRYPT_NIM_H_

/*
 * Additional CC compiler flags (see libtomcrypt/doc/crypt.pdf):
 *
 * ARGTYPE         This lets you control how the LTC_ARGCHK macro will behave.
 *                 The macro is used to check pointers inside the functions
 *                 against NULL. There are four settings for ARGTYPE. When
 *                 set to 0, it will have the default behaviour of printing
 *                 a message to stderr and raising a SIGABRT signal. This is
 *                 provided so all platforms that use LibTomCrypt can have an
 *                 error that functions similarly. When set to 1, it will
 *                 simply pass on to the assert() macro. When set to 2, the
 *                 macro will display the error to stderr then return
 *                 execution to the caller. This could lead to a segmentation
 *                 fault (e.g. when a pointer is NULL) but is useful if you
 *                 handle signals on your own. When set to 3, it will resolve
 *                 to a empty macro and no error checking will be performed.
 *                 Finally, when set to 4, it will return CRYPT_INVALID_ARG
 *                 to the caller.
 *
 * LTC_TEST        When this has been deﬁned the various self–test functions
 *                 (for ciphers, hashes, prngs, etc) are included in the
 *                 build. This is the default conﬁguration. If LTC_NO_TEST
 *                 has been deﬁned, the testing routines will be compacted
 *                 and only return CRYPT_NOP.
 *
 * LTC_NO_FAST     When this has been deﬁned the library will not use faster
 *                 word oriented operations. By default, they are only enabled
 *                 for platforms which can be auto-detected. This macro
 *                 ensures that they are never enabled.
 *
 * LTC_FAST        This mode (auto-detected with x86 32,x86 64 platforms with
 *                  GCC or MSVC) conﬁgures various routines such as ctr
 *                 encrypt() or cbc encrypt() that it can safely XOR multiple
 *                 octets in one step by using a larger data type. This has
 *                 the beneﬁt of cutting down the overhead of the respective
 *                 functions.
 *
 *                 This mode does have one downside. It can cause unaligned
 *                 reads from memory if you are not careful with the
 *                 functions. This is why it has been enabled by default only
 *                 for the x86 class of processors where unaligned accesses
 *                 are allowed. Technically LTC_FAST is not portable since
 *                 unaligned accesses are not covered by the ISO C
 *                 speciﬁcations. In practice however, you can use it on
 *                 pretty much any platform (even MIPS) with care.
 *
 *                 By design the fast mode functions won’t get unaligned on
 *                 their own. For instance, if you call ctr encrypt() right
 *                 after calling ctr start() and all the inputs you gave are
 *                 aligned than ctr encrypt() will perform aligned memory
 *                 operations only. However, if you call ctr encrypt() with
 *                 an odd amount of plaintext then call it again the CTR pad
 *                 (the IV) will be partially used. This will cause the ctr
 *                 routine to ﬁrst use up the remaining pad bytes. Then if
 *                 there are enough plaintext bytes left it will use whole
 *                 word XOR operations. These operations will be unaligned.
 *                 The simplest precaution is to make sure you process all
 *                 data in power of two blocks and handle remainder at the
 *                 end. e.g. If you are CTR’ing a long stream process it in
 *                 blocks of (say) four kilobytes and handle any remaining
 *                 incomplete blocks at the end of the stream.
 *
 *                 If you do plan on using the LTC_FAST mode you have to also
 *                 deﬁne a LTC_FAST_TYPE macro which resolves to an optimal
 *                 sized data type you can perform integer operations with.
 *                 Ideally it should be four or eight bytes since it must
 *                 properly divide the size of your block cipher (e.g. 16
 *                 bytes for AES). This means sadly if you’re on a platform
 *                 with 57–bit words (or something) you can’t use this mode.
 *                 So sad.
 *
 * LTC_NO_ASM      When this has been deﬁned the library will not use any
 *                 inline assembler. Only a few platforms support assembler
 *                 inlines but various versions of ICC and GCC cannot handle
 *                 all of the assembler functions.
 *
 * LTC_SMALL_CODE  When this is defined some of the code such as the Rijndael
 *                 and SAFER+ ciphers are replaced with smaller code variants.
 *                 These variants are slower but can save quite a bit of code
 *                 space.
 */

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#define ARGTYPE 4
#define LTC_SMALL_CODE

/* Helpers */
#define crypt_argchk   ltc_crypt_argchk
#define zeromem        ltc_zeromem

/* SHA */
#define LTC_NO_HASHES
#define LTC_SHA256
#define sha256_test    ltc_sha256_test
#define sha256_init    ltc_sha256_init
#define sha256_process ltc_sha256_process
#define sha256_done    ltc_sha256_done

/* AES */
#define LTC_NO_CIPHERS
#define LTC_RIJNDAEL

/* FORTUNA */
#define LTC_NO_PRNGS
#define LTC_FORTUNA
#define LTC_FORTUNA_WD    10 /* reseed every N read function calls */
#define LTC_FORTUNA_POOLS 32
#define LTC_RNG_GET_BYTES

#ifdef HAVE_DEV_RANDOM
# define LTC_DEVRANDOM
# ifdef DEV_URANDOM
# define LTC_TRY_URANDOM_FIRST
# endif
#else /* HAVE_DEV_RANDOM */
# ifndef HAVE_CONFIG_H
#  define LTC_DEVRANDOM /* try anyway */
#  define LTC_TRY_URANDOM_FIRST
# endif
#endif /* HAVE_DEV_RANDOM */

/* Disable others */
#define XMALLOC    _XMALLOC_is_not_allowed_here_
#define  malloc     _malloc_is_not_allowed_here_
#define XFREE        _XFREE_is_not_allowed_here_
#define  free         _free_is_not_allowed_here_
#define XREALLOC  _XREALLOC_is_not_allowed_here_
#define  realloc   _realloc_is_not_allowed_here_
#define XCALLOC    _XCALLOC_is_not_allowed_here_
#define  calloc     _calloc_is_not_allowed_here_

#endif /* TOMCRYPT_NIM_H_ */
