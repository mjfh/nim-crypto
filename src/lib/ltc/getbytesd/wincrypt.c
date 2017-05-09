/* -*- linux-c -*-
 *
 * Interface for Windows <wincrypt.h>
 *
 * Note that NIM has problems importing this file, so this wrapper here
 * does the job.
 *
 * $Id$
 *
 * Copyright (c) 2017 Jordan Hrycaj <jordan@teddy-net.com>
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted.
 *
 * The author or authors of this code dedicate any and all copyright interest
 * in this code to the public domain. We make this dedication for the benefit
 * of the public at large and to the detriment of our heirs and successors.
 * We intend this dedication to be an overt act of relinquishment in
 * perpetuity of all present and future rights to this code under copyright
 * law.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <wincrypt.h>

static inline
int /* bool */ ackq_context (HCRYPTPROV *Prov, DWORD ctx)
{
	return CryptAcquireContext
		(Prov, NULL, MS_DEF_PROV, PROV_RSA_FULL, ctx) != FALSE;
}

unsigned long rng_win32 (unsigned char *buf, unsigned long len)
{
	HCRYPTPROV hProv = 0;

	if (ackq_context (&hProv, (CRYPT_VERIFYCONTEXT  |
				   CRYPT_MACHINE_KEYSET )) != FALSE ||

	    ackq_context (&hProv, (CRYPT_VERIFYCONTEXT  |
				   CRYPT_MACHINE_KEYSET |
				   CRYPT_NEWKEYSET      )) != FALSE) {

		if (CryptGenRandom (hProv, len, buf) != TRUE) {
			len = 0;
		}

		CryptReleaseContext (hProv, 0);
	}

	return len;
}

/* End */
