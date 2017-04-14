/* -*- linux-c -*-
 *
 * debugging helper function
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

#include <stddef.h>
#include "libuecc/ecc.h"

int *uecc_specs(void)
{
	static int result[20];
	int n = 0;

	result[n++] = offsetof(ecc_25519_work_t, X);
	result[n++] = offsetof(ecc_25519_work_t, Y);
	result[n++] = offsetof(ecc_25519_work_t, Z);
	result[n++] = offsetof(ecc_25519_work_t, T);
	result[n++] =   sizeof(ecc_25519_work_t);

	result[n++] = offsetof(ecc_int256_t, p);
	result[n++] =   sizeof(ecc_int256_t);
	result[n++] = 0xffff ;

	return result;
}

/* End */
