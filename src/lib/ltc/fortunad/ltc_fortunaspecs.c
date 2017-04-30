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

#include "tomcrypt.h"

int *ltc_fortuna_specs(void)
{
	static int result[20];
	int n = 0;

	result[n++] = offsetof(prng_state, fortuna.pool);
	result[n++] = offsetof(prng_state, fortuna.pool[1]);
	result[n++] = offsetof(prng_state, fortuna.skey);
	result[n++] = offsetof(prng_state, fortuna.K);
	result[n++] = offsetof(prng_state, fortuna.IV);
	result[n++] = offsetof(prng_state, fortuna.pool_idx);
	result[n++] = offsetof(prng_state, fortuna.pool0_len);
	result[n++] = offsetof(prng_state, fortuna.wd);
	result[n++] = offsetof(prng_state, fortuna.reset_cnt);
	result[n++] =   sizeof(struct fortuna_prng);
	result[n++] =   sizeof(prng_state);
	result[n++] = 0xffff ;

	return result;
}

/* End */
