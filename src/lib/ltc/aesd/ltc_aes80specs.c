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

int *ltc_aes80_specs(void)
{
	static int result[20];
	int n = 0;

	result[n++] = offsetof(symmetric_key, rijndael.eK);
	result[n++] = offsetof(symmetric_key, rijndael.dK);
	result[n++] = offsetof(symmetric_key, rijndael.Nr);
	result[n++] =   sizeof(struct rijndael_key);
	result[n++] =   sizeof(symmetric_key);
	result[n++] = 0xffff ;

	return result;
}

#if defined (__GNUC__)
# ifdef LTC_DES
#  error LTC_DES should not be defined!
# endif

# ifdef LTC_RC2
#  error LTC_RC2 should not be defined!
# endif

# ifdef LTC_SAFER
#  error LTC_SAFER should not be defined!
# endif

# ifdef LTC_TWOFISH
#  error LTC_TWOFISH should not be defined!
# endif

# ifdef LTC_BLOWFISH
#  error LTC_BLOWFISH should not be defined!
# endif

# ifdef LTC_RC5
#  error LTC_RC5 should not be defined!
# endif

# ifdef LTC_RC6
#  error LTC_RC6 should not be defined!
# endif

# ifdef LTC_SAFERP
#  error LTC_SAFERP should not be defined!
# endif

/* #ifdef LTC_RIJNDAEL */
/* #endif */

# ifdef LTC_XTEA
#  error LTC_XTEA should not be defined!
# endif

# ifdef LTC_CAST5
#  error LTC_CAST5 should not be defined!
# endif

# ifdef LTC_NOEKEON
#  error LTC_NOEKEON should not be defined!
# endif

# ifdef LTC_SKIPJACK
#  error LTC_SKIPJACK should not be defined!
# endif

# ifdef LTC_KHAZAD
#  error LTC_KHAZAD should not be defined!
# endif

# ifdef LTC_ANUBIS
#  error LTC_ANUBIS should not be defined!
# endif

# ifdef LTC_KSEED
#  error LTC_KSEED should not be defined!
# endif

# ifdef LTC_KASUMI
#  error LTC_KASUMI should not be defined!
# endif

# ifdef LTC_MULTI2
#  error LTC_MULTI2 should not be defined!
# endif

# ifdef LTC_CAMELLIA
#  error LTC_CAMELLIA should not be defined!
# endif
#endif /* __GNUC__ */

/* end */
