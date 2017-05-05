/* -*- linux-c -*-
 *
 * LibTomCrypt, modular cryptographic library -- Tom St Denis
 *
 * LibTomCrypt is a library that provides various cryptographic
 * algorithms in a highly modular and flexible manner.
 *
 * The library is free for all purposes without any express
 * guarantee it works.
 *
 * Tom St Denis, tomstdenis@gmail.com, http://libtom.org
 */
#include "tomcrypt.h"

/*
 * Re-factored version, mostly fiddling about with configuration parameters
 *
 * Blame: jordan@teddy-net.com
 */

#ifdef LTC_RNG_GET_BYTES

/* ----------------------------------------------------------------------- *
 * Entropy from random devices
 * ----------------------------------------------------------------------- */

#ifdef LTC_DEVRANDOM
/**
   @file rng_get_bytes.c
   portable way to get secure random bits to feed a PRNG (Tom St Denis)
*/

#ifndef DEV_URANDOM
# define DEV_URANDOM "/dev/urandom"
#endif
#ifndef DEV_RANDOM
# define DEV_RANDOM "/dev/random"
#endif

static inline
FILE *open_random (void)
{
	FILE *f ;

#	ifdef LTC_TRY_URANDOM_FIRST
	f = fopen (DEV_URANDOM, "rb");
	if (f == NULL)
		f = fopen (DEV_RANDOM, "rb");
#	else
	f = fopen (DEV_RANDOM, "rb");
#	endif /* LTC_TRY_URANDOM_FIRST */

	return f;
}

static inline
unsigned long rng_nix(unsigned char *buf, unsigned long len)
{
	unsigned long x = 0 ;

#	ifdef LTC_NO_FILE
	LTC_UNUSED_PARAM (buf);
	LTC_UNUSED_PARAM (len);
#	else /* LTC_NO_FILE */

	FILE *f = open_random ();
	if (f != NULL) {
		/* disable buffering */
		if (setvbuf(f, NULL, _IONBF, 0) == 0) {
			x = (unsigned long)
				fread (buf, 1, (size_t)len, f);
		}

		fclose(f);
	}
#	endif /* LTC_NO_FILE */

	return x;
}
#endif /* LTC_DEVRANDOM */

/* ----------------------------------------------------------------------- *
 * Entropy from clock() service (ANSI)
 * ----------------------------------------------------------------------- */

/* on ANSI C platforms with 100 < CLOCKS_PER_SEC < 10000 */
#if defined (CLOCKS_PER_SEC) && !defined (WINCE)

#define ANSI_RNG

#ifdef CLOCKS_PER_SEC
#ifdef _POSIX_CLOCKRES_MIN
#if 10000 < _POSIX_CLOCKRES_MIN /* 1000000 on a POSIX system */
# define YCLOCKS_PER_SEC   (10000)
# define YCLOCK_SCALE_DOWN ((CLOCKS_PER_SEC * 100) / 1000000)
// # undef  XCLOCK
# define XCLOCK()          (clock () / YCLOCK_SCALE_DOWN)
#endif /* 10000 */
#endif /* _POSIX_CLOCKRES_MIN */
#endif /* CLOCKS_PER_SEC */

static inline
unsigned long rng_ansic(unsigned char *buf,
			unsigned long len,
			void (*callback) (void*), void *dsc)
{
	int cur_len, acc, a, b;

#	ifndef YCLOCK_SCALE_DOWN
	/* macro XCLOCKS_PER_SEC looks like: (clock_t)<some-number> */
	if (XCLOCKS_PER_SEC < 100 || XCLOCKS_PER_SEC > 10000) {return 0;}
#	endif

	cur_len = acc = a = b = 0;

	while (cur_len < len) {
		int bits = 8;

		if (callback != NULL)
			callback (dsc);

		while (bits --) {

			do {
				clock_t t1 = XCLOCK ();
				while (t1 == XCLOCK ()) {
					a ^= 1;
				}
				t1 = XCLOCK();
				while (t1 == XCLOCK ()) {
					b ^= 1;
				}
			}
			while (a == b);

			acc = (acc << 1) | a;
		}

		* buf ++ = acc;
		acc      =   0;
		cur_len ++ ;
	}

	acc = a = b = 0;
	return cur_len;
}
#endif /* CLOCKS_PER_SEC && not WINCE */

/* ----------------------------------------------------------------------- *
 * Entropy on Windows platform
 * ----------------------------------------------------------------------- */

/* Try the Microsoft CSP */
#if defined (WIN32) || defined (_WIN32) || defined (WINCE)

#define WINDOWS_RNG

#ifndef _WIN32_WINNT
# define _WIN32_WINNT 0x0400
#endif
#ifdef WINCE
# define UNDER_CE
# define ARM
#endif

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <wincrypt.h>

static inline
int /* bool */ ackq_context (HCRYPTPROV *Prov, DWORD ctx)
{
	return CryptAcquireContext
		(Prov, NULL, MS_DEF_PROV, PROV_RSA_FULL, ctx) == 0;
}

static inline
unsigned long rng_win32 (unsigned char *buf, unsigned long len)
{
	HCRYPTPROV hProv = 0;
	if (ackq_context (&hProv, (CRYPT_VERIFYCONTEXT  |
				   CRYPT_MACHINE_KEYSET )) == 0 &&

	    ackq_context (&hProv, (CRYPT_VERIFYCONTEXT  |
				   CRYPT_MACHINE_KEYSET |
				   CRYPT_NEWKEYSET      )) == 0)
		return 0;

	if (CryptGenRandom (hProv, len, buf) != TRUE) {
		len = 0;
	}

	CryptReleaseContext (hProv, 0);
	return len;
}
#endif /* WIN32 || _WIN32 || WINCE */

/* ----------------------------------------------------------------------- *
 * Public interface (if enabled)
 * ----------------------------------------------------------------------- */

/**
  Read the system RNG
  @param out       Destination
  @param outlen    Length desired (octets)
  @param callback  Pointer to void function to act as "callback" when RNG is slow.  This can be NULL
  @return Number of octets read
*/
unsigned long rng_get_bytes(unsigned char *out,
			    unsigned long outlen,
                            void (*callback) (void*), void *dsc)
{
	unsigned long x ;
	LTC_ARGCHK(out != NULL);

#	ifdef LTC_DEVRANDOM
	x = rng_nix (out, outlen);
	if (x != 0) {
		return x;
	}
#	endif

#	ifdef WINDOWS_RNG
	x = rng_win32 (out, outlen);
	if (x != 0) {
		return x;
	}
#	endif

#	ifdef ANSI_RNG
	x = rng_ansic (out, outlen, callback, dsc);
	if (x != 0) {
		return x;
	}
#	else
	LTC_UNUSED_PARAM (callback);
	LTC_UNUSED_PARAM (dsc);
#	endif

	return 0;
}
#endif /* LTC_RNG_GET_BYTES */

/* $Source$ */
/* $Revision$ */
/* $Date$ */

/* ----------------------------------------------------------------------- *
 * End
 * ----------------------------------------------------------------------- */
