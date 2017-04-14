/* -*- linux-c -*-
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
 *
 * Interface NIM library <= libsession.a
 *
 * Compile:
 *    crylib=..
 *    nim c -p:$crylib --app:staticLib --noMain --header session.nim
 *
 *    nimlib=`nim dump 2>&1 >/dev/null|sed '$!d'`
 *    gcc -o main -Inimcache -I$nimlib main.c libsession.a -ldl -lm
 */

#include "session.h"
#include <stdio.h>

/* see kris kristofferson: to beat the devil */
static char kk [] =
	"If you waste your time a talking\n"
	"To the people who don't listen\n"
	"To the things that you are saying\n"
	"Who do you thinks gonna hear?"
	;

static void *prv_key, *pub_key, *plain_text, *cipher_text ;

int main(int argc, char**argv)
{
	char *text = argc < 2
		? kk
		: argv [1]
		;

	NimMain ();

	/* generate keys */
	prv_key = prvkey ();
	pub_key = pubkey (prv_key);

	/* plain */
	printf ("\n*** Message:\n%s\n", text);

	/* encrypt */
	cipher_text = b64_encrypt (text, pub_key);
	printf ("\n*** Encrypted message:\n%s\n", cipher_text);

	/* decrypt */
	plain_text = b64_decrypt (cipher_text, prv_key);
	printf ("\n*** Decrypted message:\n%s\n", plain_text);

	/* done */
	printf ("\n*** Now try again with another message\n\n"
		"Usage: %s <message>\n", argv [0]);

	freekey (prv_key);
	freekey (pub_key);
	return 0;
}

/* end */
