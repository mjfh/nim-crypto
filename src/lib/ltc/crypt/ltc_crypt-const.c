/* -*- linux-c -*-
 *
 * interface for LTC constants
 *
 * $Id$
 *
 * Copyright (c) 2017 Jordan Hrycaj <jordan@teddy-net.com>
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
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

#include "tomcrypt.h"

const char *ltc_const(int n)
{
#	define X(sym) case sym: return #sym

	switch(n) {
	X(CRYPT_OK);
	X(CRYPT_ERROR);
	X(CRYPT_NOP);

	X(CRYPT_INVALID_KEYSIZE);
	X(CRYPT_INVALID_ROUNDS);
	X(CRYPT_FAIL_TESTVECTOR);

	X(CRYPT_BUFFER_OVERFLOW);
	X(CRYPT_INVALID_PACKET);

	X(CRYPT_INVALID_PRNGSIZE);
	X(CRYPT_ERROR_READPRNG);

	X(CRYPT_INVALID_CIPHER);
	X(CRYPT_INVALID_HASH);
	X(CRYPT_INVALID_PRNG);

	X(CRYPT_MEM);

	X(CRYPT_PK_TYPE_MISMATCH);
	X(CRYPT_PK_NOT_PRIVATE);

	X(CRYPT_INVALID_ARG);
	X(CRYPT_FILE_NOTFOUND);

	X(CRYPT_PK_INVALID_TYPE);
	X(CRYPT_PK_INVALID_SYSTEM);
	X(CRYPT_PK_DUP);
	X(CRYPT_PK_NOT_FOUND);
	X(CRYPT_PK_INVALID_SIZE);

	X(CRYPT_INVALID_PRIME_SIZE);
	X(CRYPT_PK_INVALID_PADDING);

	X(CRYPT_HASH_OVERFLOW);
	}

	return 0;
}

/* end */
