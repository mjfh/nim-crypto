/*
  Copyright (c) 2012-2015, Matthias Schiffer <mschiffer@universe-factory.net>
  Partly based on public domain code by Matthew Dempsky and D. J. Bernstein.
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice,
       this list of conditions and the following disclaimer.
    2. Redistributions in binary form must reproduce the above copyright notice,
       this list of conditions and the following disclaimer in the documentation
       and/or other materials provided with the distribution.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/** \file
 * EC group operations for Twisted Edwards Curve \f$ ax^2 + y^2 = 1 + dx^2y^2 \f$
 * on prime field \f$ p = 2^{255} - 19 \f$.
 *
 * Two different (isomorphic) sets of curve parameters are supported:
 *
 *    \f$ a = 486664 \f$ and
 *    \f$ d = 486660 \f$
 * are the parameters used by the original libuecc implementation (till v5).
 * To use points on this curve, use the functions with the suffix \em legacy.
 *
 * The other supported curve uses the parameters
 *    \f$ a = -1 \f$ and
 *    \f$ d = -(121665/121666) \f$,
 * which is the curve used by the Ed25519 algorithm. The functions for this curve
 * have the suffix \em ed25519.
 *
 * Internally, libuecc always uses the latter representation for its \em work structure.
 *
 * The curves are equivalent to the Montgomery Curve used in D. J. Bernstein's
 * Curve25519 Diffie-Hellman algorithm.
 *
 * See http://hyperelliptic.org/EFD/g1p/auto-twisted-extended.html for add and
 * double operations.
 *
 * Doxygen comments for public APIs can be found in the public header file.
 *
 * Invariant that must be held by all public API: the components of an
 * \ref ecc_25519_work_t are always in the range \f$ [0, 2p) \f$.
 * Integers in this range will be called \em squeezed in the following.
 */

#include <libuecc/ecc.h>


const ecc_25519_work_t ecc_25519_work_identity = {{0}, {1}, {1}, {0}};

const ecc_25519_work_t ecc_25519_work_base_legacy = {
	{0x1a, 0xd5, 0x25, 0x8f, 0x60, 0x2d, 0x56, 0xc9,
	 0xb2, 0xa7, 0x25, 0x95, 0x60, 0xc7, 0x2c, 0x69,
	 0x5c, 0xdc, 0xd6, 0xfd, 0x31, 0xe2, 0xa4, 0xc0,
	 0xfe, 0x53, 0x6e, 0xcd, 0xd3, 0x36, 0x69, 0x21},
	{0x58, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66,
	 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66,
	 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66,
	 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66},
	{1},
	{0xa3, 0xdd, 0xb7, 0xa5, 0xb3, 0x8a, 0xde, 0x6d,
	 0xf5, 0x52, 0x51, 0x77, 0x80, 0x9f, 0xf0, 0x20,
	 0x7d, 0xe3, 0xab, 0x64, 0x8e, 0x4e, 0xea, 0x66,
	 0x65, 0x76, 0x8b, 0xd7, 0x0f, 0x5f, 0x87, 0x67},
};

const ecc_25519_work_t ecc_25519_work_default_base = {
	{0x1a, 0xd5, 0x25, 0x8f, 0x60, 0x2d, 0x56, 0xc9,
	 0xb2, 0xa7, 0x25, 0x95, 0x60, 0xc7, 0x2c, 0x69,
	 0x5c, 0xdc, 0xd6, 0xfd, 0x31, 0xe2, 0xa4, 0xc0,
	 0xfe, 0x53, 0x6e, 0xcd, 0xd3, 0x36, 0x69, 0x21},
	{0x58, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66,
	 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66,
	 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66,
	 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66},
	{1},
	{0xa3, 0xdd, 0xb7, 0xa5, 0xb3, 0x8a, 0xde, 0x6d,
	 0xf5, 0x52, 0x51, 0x77, 0x80, 0x9f, 0xf0, 0x20,
	 0x7d, 0xe3, 0xab, 0x64, 0x8e, 0x4e, 0xea, 0x66,
	 0x65, 0x76, 0x8b, 0xd7, 0x0f, 0x5f, 0x87, 0x67},
};


const ecc_25519_work_t ecc_25519_work_base_ed25519 = {
	{0x1a, 0xd5, 0x25, 0x8f, 0x60, 0x2d, 0x56, 0xc9,
	 0xb2, 0xa7, 0x25, 0x95, 0x60, 0xc7, 0x2c, 0x69,
	 0x5c, 0xdc, 0xd6, 0xfd, 0x31, 0xe2, 0xa4, 0xc0,
	 0xfe, 0x53, 0x6e, 0xcd, 0xd3, 0x36, 0x69, 0x21},
	{0x58, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66,
	 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66,
	 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66,
	 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66},
	{1},
	{0xa3, 0xdd, 0xb7, 0xa5, 0xb3, 0x8a, 0xde, 0x6d,
	 0xf5, 0x52, 0x51, 0x77, 0x80, 0x9f, 0xf0, 0x20,
	 0x7d, 0xe3, 0xab, 0x64, 0x8e, 0x4e, 0xea, 0x66,
	 0x65, 0x76, 0x8b, 0xd7, 0x0f, 0x5f, 0x87, 0x67},
};


static const uint32_t zero[32] = {0};
static const uint32_t one[32] = {1};

static const uint32_t minus1[32] = {
	0xec, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x7f,
};

/** Ed25519 parameter -(121665/121666) */
static const uint32_t d[32] = {
	0xa3, 0x78, 0x59, 0x13, 0xca, 0x4d, 0xeb, 0x75,
	0xab, 0xd8, 0x41, 0x41, 0x4d, 0x0a, 0x70, 0x00,
	0x98, 0xe8, 0x79, 0x77, 0x79, 0x40, 0xc7, 0x8c,
	0x73, 0xfe, 0x6f, 0x2b, 0xee, 0x6c, 0x03, 0x52,
};


/** Factor to multiply the X coordinate with to convert from the legacy to the Ed25519 curve */
static const uint32_t legacy_to_ed25519[32] = {
	0xe7, 0x81, 0xba, 0x00, 0x55, 0xfb, 0x91, 0x33,
	0x7d, 0xe5, 0x82, 0xb4, 0x2e, 0x2c, 0x5e, 0x3a,
	0x81, 0xb0, 0x03, 0xfc, 0x23, 0xf7, 0x84, 0x2d,
	0x44, 0xf9, 0x5f, 0x9f, 0x0b, 0x12, 0xd9, 0x70,
};

/** Factor to multiply the X coordinate with to convert from the Ed25519 to the legacy curve */
static const uint32_t ed25519_to_legacy[32] = {
	0xe9, 0x68, 0x42, 0xdb, 0xaf, 0x04, 0xb4, 0x40,
	0xa1, 0xd5, 0x43, 0xf2, 0xf9, 0x38, 0x31, 0x28,
	0x01, 0x17, 0x05, 0x67, 0x9b, 0x81, 0x61, 0xf8,
	0xa9, 0x5b, 0x3e, 0x6a, 0x20, 0x67, 0x4b, 0x24,
};


/** Adds two unpacked integers (modulo p) */
static void add(uint32_t out[32], const uint32_t a[32], const uint32_t b[32]) {
	unsigned int j;
	uint32_t u;

	u = 0;

	for (j = 0; j < 31; j++) {
		u += a[j] + b[j];
		out[j] = u & 255;
		u >>= 8;
	}

	u += a[31] + b[31];
	out[31] = u;
}

/**
 * Subtracts two unpacked integers (modulo p)
 *
 * b must be \em squeezed.
 */
static void sub(uint32_t out[32], const uint32_t a[32], const uint32_t b[32]) {
	unsigned int j;
	uint32_t u;

	u = 218;

	for (j = 0;j < 31;++j) {
		u += a[j] + UINT32_C(65280) - b[j];
		out[j] = u & 255;
		u >>= 8;
	}

	u += a[31] - b[31];
	out[31] = u;
}

/**
 * Performs carry and reduce on an unpacked integer
 *
 * The result is not always fully reduced, but it will be significantly smaller than \f$ 2p \f$.
 */
static void squeeze(uint32_t a[32]) {
	unsigned int j;
	uint32_t u;

	u = 0;

	for (j = 0;j < 31;++j) {
		u += a[j];
		a[j] = u & 255;
		u >>= 8;
	}

	u += a[31];
	a[31] = u & 127;
	u = 19 * (u >> 7);

	for (j = 0;j < 31;++j) {
		u += a[j];
		a[j] = u & 255;
		u >>= 8;
	}

	u += a[31];
	a[31] = u;
}


static const uint32_t minusp[32] = {
	19, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 128
};

/**
 * Ensures that the output of a previous \ref squeeze is fully reduced
 *
 * After a \ref freeze, only the lower byte of each integer part holds a meaningful value.
 */
static void freeze(uint32_t a[32]) {
	uint32_t aorig[32];
	unsigned int j;
	uint32_t negative;

	for (j = 0; j < 32; j++)
		aorig[j] = a[j];
	add(a, a, minusp);
	negative = -((a[31] >> 7) & 1);

	for (j = 0; j < 32; j++)
		a[j] ^= negative & (aorig[j] ^ a[j]);
}

/**
 * Returns the parity (lowest bit of the fully reduced value) of a
 *
 * The input must be \em squeezed.
 */
static int parity(const uint32_t a[32]) {
	uint32_t b[32];

	add(b, a, minusp);
	return (a[0] ^ (b[31] >> 7) ^ 1) & 1;
}

/**
 * Multiplies two unpacked integers (modulo p)
 *
 * The result will be \em squeezed.
 */
static void mult(uint32_t out[32], const uint32_t a[32], const uint32_t b[32]) {
	unsigned int i, j;
	uint32_t u;

	for (i = 0; i < 32; ++i) {
		u = 0;

		for (j = 0; j <= i; j++)
			u += a[j] * b[i - j];

		for (j = i + 1; j < 32; j++)
			u += 38 * a[j] * b[i + 32 - j];

		out[i] = u;
	}

	squeeze(out);
}

/**
 * Multiplies an unpacked integer with a small integer (modulo p)
 *
 * The result will be \em squeezed.
 */
static void mult_int(uint32_t out[32], uint32_t n, const uint32_t a[32]) {
	unsigned int j;
	uint32_t u;

	u = 0;

	for (j = 0; j < 31; j++) {
		u += n * a[j];
		out[j] = u & 255;
		u >>= 8;
	}

	u += n * a[31]; out[31] = u & 127;
	u = 19 * (u >> 7);

	for (j = 0; j < 31; j++) {
		u += out[j];
		out[j] = u & 255;
		u >>= 8;
	}

	u += out[j];
	out[j] = u;
}

/**
 * Squares an unpacked integer
 *
 * The result will be sqeezed.
 */
static void square(uint32_t out[32], const uint32_t a[32]) {
	unsigned int i, j;
	uint32_t u;

	for (i = 0; i < 32; i++) {
		u = 0;

		for (j = 0; j < i - j; j++)
			u += a[j] * a[i - j];

		for (j = i + 1; j < i + 32 - j; j++)
			u += 38 * a[j] * a[i + 32 - j];

		u *= 2;

		if ((i & 1) == 0) {
			u += a[i / 2] * a[i / 2];
			u += 38 * a[i / 2 + 16] * a[i / 2 + 16];
		}

		out[i] = u;
	}

	squeeze(out);
}

/** Checks for the equality of two unpacked integers */
static int check_equal(const uint32_t x[32], const uint32_t y[32]) {
	uint32_t differentbits = 0;
	int i;

	for (i = 0; i < 32; i++) {
		differentbits |= ((x[i] ^ y[i]) & 0xffff);
		differentbits |= ((x[i] ^ y[i]) >> 16);
	}

	return (1 & ((differentbits - 1) >> 16));
}

/**
 * Checks if an unpacked integer equals zero (modulo p)
 *
 * The integer must be squeezed before.
 */
static int check_zero(const uint32_t x[32]) {
	static const uint32_t p[32] = {
		0xed, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
		0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
		0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
		0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x7f
	};

	return (check_equal(x, zero) | check_equal(x, p));
}

/** Copies r to out when b == 0, s when b == 1 */
static void selectw(ecc_25519_work_t *out, const ecc_25519_work_t *r, const ecc_25519_work_t *s, uint32_t b) {
	unsigned int j;
	uint32_t t;
	uint32_t bminus1;

	bminus1 = b - 1;
	for (j = 0; j < 32; ++j) {
		t = bminus1 & (r->X[j] ^ s->X[j]);
		out->X[j] = s->X[j] ^ t;

		t = bminus1 & (r->Y[j] ^ s->Y[j]);
		out->Y[j] = s->Y[j] ^ t;

		t = bminus1 & (r->Z[j] ^ s->Z[j]);
		out->Z[j] = s->Z[j] ^ t;

		t = bminus1 & (r->T[j] ^ s->T[j]);
		out->T[j] = s->T[j] ^ t;
	}
}

/** Copies r to out when b == 0, s when b == 1 */
static void select(uint32_t out[32], const uint32_t r[32], const uint32_t s[32], uint32_t b) {
	unsigned int j;
	uint32_t t;
	uint32_t bminus1;

	bminus1 = b - 1;
	for (j = 0;j < 32;++j) {
		t = bminus1 & (r[j] ^ s[j]);
		out[j] = s[j] ^ t;
	}
}

/**
 * Computes the square root of an unpacked integer (in the prime field modulo p)
 *
 * If the given integer has no square root, 0 is returned, 1 otherwise.
 */
static int square_root(uint32_t out[32], const uint32_t z[32]) {
	static const uint32_t rho_s[32] = {
		0xb0, 0xa0, 0x0e, 0x4a, 0x27, 0x1b, 0xee, 0xc4,
		0x78, 0xe4, 0x2f, 0xad, 0x06, 0x18, 0x43, 0x2f,
		0xa7, 0xd7, 0xfb, 0x3d, 0x99, 0x00, 0x4d, 0x2b,
		0x0b, 0xdf, 0xc1, 0x4f, 0x80, 0x24, 0x83, 0x2b
	};

	/* raise z to power (2^252-2), check if power (2^253-5) equals -1 */

	uint32_t z2[32];
	uint32_t z9[32];
	uint32_t z11[32];
	uint32_t z2_5_0[32];
	uint32_t z2_10_0[32];
	uint32_t z2_20_0[32];
	uint32_t z2_50_0[32];
	uint32_t z2_100_0[32];
	uint32_t t0[32];
	uint32_t t1[32];
	uint32_t z2_252_1[32];
	uint32_t z2_252_1_rho_s[32];
	int i;

	/* 2 */ square(z2, z);
	/* 4 */ square(t1, z2);
	/* 8 */ square(t0, t1);
	/* 9 */ mult(z9, t0, z);
	/* 11 */ mult(z11, z9, z2);
	/* 22 */ square(t0, z11);
	/* 2^5 - 2^0 = 31 */ mult(z2_5_0, t0, z9);

	/* 2^6 - 2^1 */ square(t0, z2_5_0);
	/* 2^7 - 2^2 */ square(t1, t0);
	/* 2^8 - 2^3 */ square(t0, t1);
	/* 2^9 - 2^4 */ square(t1, t0);
	/* 2^10 - 2^5 */ square(t0, t1);
	/* 2^10 - 2^0 */ mult(z2_10_0, t0, z2_5_0);

	/* 2^11 - 2^1 */ square(t0, z2_10_0);
	/* 2^12 - 2^2 */ square(t1, t0);
	/* 2^20 - 2^10 */ for (i = 2; i < 10; i += 2) { square(t0, t1); square(t1, t0); }
	/* 2^20 - 2^0 */ mult(z2_20_0, t1, z2_10_0);

	/* 2^21 - 2^1 */ square(t0, z2_20_0);
	/* 2^22 - 2^2 */ square(t1, t0);
	/* 2^40 - 2^20 */ for (i = 2; i < 20; i += 2) { square(t0, t1); square(t1, t0); }
	/* 2^40 - 2^0 */ mult(t0, t1, z2_20_0);

	/* 2^41 - 2^1 */ square(t1, t0);
	/* 2^42 - 2^2 */ square(t0, t1);
	/* 2^50 - 2^10 */ for (i = 2; i < 10; i += 2) { square(t1, t0); square(t0, t1); }
	/* 2^50 - 2^0 */ mult(z2_50_0, t0, z2_10_0);

	/* 2^51 - 2^1 */ square(t0, z2_50_0);
	/* 2^52 - 2^2 */ square(t1, t0);
	/* 2^100 - 2^50 */ for (i = 2; i < 50; i += 2) { square(t0, t1); square(t1, t0); }
	/* 2^100 - 2^0 */ mult(z2_100_0, t1, z2_50_0);

	/* 2^101 - 2^1 */ square(t1, z2_100_0);
	/* 2^102 - 2^2 */ square(t0, t1);
	/* 2^200 - 2^100 */ for (i = 2; i < 100; i += 2) { square(t1, t0); square(t0, t1); }
	/* 2^200 - 2^0 */ mult(t1, t0, z2_100_0);

	/* 2^201 - 2^1 */ square(t0, t1);
	/* 2^202 - 2^2 */ square(t1, t0);
	/* 2^250 - 2^50 */ for (i = 2; i < 50; i += 2) { square(t0, t1); square(t1, t0); }
	/* 2^250 - 2^0 */ mult(t0, t1, z2_50_0);

	/* 2^251 - 2^1 */ square(t1, t0);
	/* 2^252 - 2^2 */ square(t0, t1);
	/* 2^252 - 2^1 */ mult(z2_252_1, t0, z2);

	/* 2^253 - 2^3 */ square(t1, t0);
	/* 2^253 - 6 */ mult(t0, t1, z2);
	/* 2^253 - 5 */ mult(t1, t0, z);

	mult(z2_252_1_rho_s, z2_252_1, rho_s);

	select(out, z2_252_1, z2_252_1_rho_s, check_equal(t1, minus1));

	/* Check the root */
	square(t0, out);
	return check_equal(t0, z);
}

/** Computes the reciprocal of an unpacked integer (in the prime field modulo p) */
static void recip(uint32_t out[32], const uint32_t z[32]) {
	uint32_t z2[32];
	uint32_t z9[32];
	uint32_t z11[32];
	uint32_t z2_5_0[32];
	uint32_t z2_10_0[32];
	uint32_t z2_20_0[32];
	uint32_t z2_50_0[32];
	uint32_t z2_100_0[32];
	uint32_t t0[32];
	uint32_t t1[32];
	int i;

	/* 2 */ square(z2, z);
	/* 4 */ square(t1, z2);
	/* 8 */ square(t0, t1);
	/* 9 */ mult(z9, t0, z);
	/* 11 */ mult(z11, z9, z2);
	/* 22 */ square(t0, z11);
	/* 2^5 - 2^0 = 31 */ mult(z2_5_0, t0, z9);

	/* 2^6 - 2^1 */ square(t0, z2_5_0);
	/* 2^7 - 2^2 */ square(t1, t0);
	/* 2^8 - 2^3 */ square(t0, t1);
	/* 2^9 - 2^4 */ square(t1, t0);
	/* 2^10 - 2^5 */ square(t0, t1);
	/* 2^10 - 2^0 */ mult(z2_10_0, t0, z2_5_0);

	/* 2^11 - 2^1 */ square(t0, z2_10_0);
	/* 2^12 - 2^2 */ square(t1, t0);
	/* 2^20 - 2^10 */ for (i = 2; i < 10; i += 2) { square(t0, t1); square(t1, t0); }
	/* 2^20 - 2^0 */ mult(z2_20_0, t1, z2_10_0);

	/* 2^21 - 2^1 */ square(t0, z2_20_0);
	/* 2^22 - 2^2 */ square(t1, t0);
	/* 2^40 - 2^20 */ for (i = 2; i < 20; i += 2) { square(t0, t1); square(t1, t0); }
	/* 2^40 - 2^0 */ mult(t0, t1, z2_20_0);

	/* 2^41 - 2^1 */ square(t1, t0);
	/* 2^42 - 2^2 */ square(t0, t1);
	/* 2^50 - 2^10 */ for (i = 2; i < 10; i += 2) { square(t1, t0); square(t0, t1); }
	/* 2^50 - 2^0 */ mult(z2_50_0, t0, z2_10_0);

	/* 2^51 - 2^1 */ square(t0, z2_50_0);
	/* 2^52 - 2^2 */ square(t1, t0);
	/* 2^100 - 2^50 */ for (i = 2; i < 50; i += 2) { square(t0, t1); square(t1, t0); }
	/* 2^100 - 2^0 */ mult(z2_100_0, t1, z2_50_0);

	/* 2^101 - 2^1 */ square(t1, z2_100_0);
	/* 2^102 - 2^2 */ square(t0, t1);
	/* 2^200 - 2^100 */ for (i = 2; i < 100; i += 2) { square(t1, t0); square(t0, t1); }
	/* 2^200 - 2^0 */ mult(t1, t0, z2_100_0);

	/* 2^201 - 2^1 */ square(t0, t1);
	/* 2^202 - 2^2 */ square(t1, t0);
	/* 2^250 - 2^50 */ for (i = 2; i < 50; i += 2) { square(t0, t1); square(t1, t0); }
	/* 2^250 - 2^0 */ mult(t0, t1, z2_50_0);

	/* 2^251 - 2^1 */ square(t1, t0);
	/* 2^252 - 2^2 */ square(t0, t1);
	/* 2^253 - 2^3 */ square(t1, t0);
	/* 2^254 - 2^4 */ square(t0, t1);
	/* 2^255 - 2^5 */ square(t1, t0);
	/* 2^255 - 21 */ mult(out, t1, z11);
}

/**
 * Checks if the X and Y coordinates of a work structure represent a valid point of the curve
 *
 * Also fills in the T coordinate.
 */
static int check_load_xy(ecc_25519_work_t *val) {
	uint32_t X2[32], Y2[32], dX2[32], dX2Y2[32], Y2_X2[32], Y2_X2_1[32], r[32];

	/* Check validity */
	square(X2, val->X);
	square(Y2, val->Y);

	mult(dX2, d, X2);
	mult(dX2Y2, dX2, Y2);

	sub(Y2_X2, Y2, X2);
	sub(Y2_X2_1, Y2_X2, one);

	sub(r, Y2_X2_1, dX2Y2);
	squeeze(r);

	if (!check_zero(r))
	    return 0;

	mult(val->T, val->X, val->Y);

	return 1;
}

int ecc_25519_load_xy_ed25519(ecc_25519_work_t *out, const ecc_int256_t *x, const ecc_int256_t *y) {
	int i;

	for (i = 0; i < 32; i++) {
		out->X[i] = x->p[i];
		out->Y[i] = y->p[i];
		out->Z[i] = (i == 0);
	}

	return check_load_xy(out);
}

int ecc_25519_load_xy_legacy(ecc_25519_work_t *out, const ecc_int256_t *x, const ecc_int256_t *y) {
	int i;
	uint32_t tmp[32];

	for (i = 0; i < 32; i++) {
		tmp[i] = x->p[i];
		out->Y[i] = y->p[i];
		out->Z[i] = (i == 0);
	}

	mult(out->X, tmp, legacy_to_ed25519);

	return check_load_xy(out);
}

int ecc_25519_load_xy(ecc_25519_work_t *out, const ecc_int256_t *x, const ecc_int256_t *y) {
	return ecc_25519_load_xy_legacy(out, x, y);
}


void ecc_25519_store_xy_ed25519(ecc_int256_t *x, ecc_int256_t *y, const ecc_25519_work_t *in) {
	uint32_t X[32], Y[32], Z[32];
	int i;

	recip(Z, in->Z);

	if (x) {
		mult(X, Z, in->X);
		freeze(X);
		for (i = 0; i < 32; i++)
			x->p[i] = X[i];
	}

	if (y) {
		mult(Y, Z, in->Y);
		freeze(Y);
		for (i = 0; i < 32; i++)
			y->p[i] = Y[i];
	}
}

void ecc_25519_store_xy_legacy(ecc_int256_t *x, ecc_int256_t *y, const ecc_25519_work_t *in) {
	uint32_t X[32], tmp[32], Y[32], Z[32];
	int i;

	recip(Z, in->Z);

	if (x) {
		mult(tmp, Z, in->X);
		mult(X, tmp, ed25519_to_legacy);
		freeze(X);
		for (i = 0; i < 32; i++)
			x->p[i] = X[i];
	}

	if (y) {
		mult(Y, Z, in->Y);
		freeze(Y);
		for (i = 0; i < 32; i++)
			y->p[i] = Y[i];
	}
}

void ecc_25519_store_xy(ecc_int256_t *x, ecc_int256_t *y, const ecc_25519_work_t *in) {
	ecc_25519_store_xy_legacy(x, y, in);
}


int ecc_25519_load_packed_ed25519(ecc_25519_work_t *out, const ecc_int256_t *in) {
	int i;
	uint32_t Y2[32] /* Y^2 */, dY2[32] /* dY^2 */, Y2_1[32] /* Y^2-1 */, dY2_1[32] /* dY^2+1 */, _1_dY2_1[32] /* 1/(dY^2+1) */;
	uint32_t X2[32] /* X^2 */, X[32], Xt[32];

	for (i = 0; i < 32; i++) {
		out->Y[i] = in->p[i];
		out->Z[i] = (i == 0);
	}

	out->Y[31] &= 0x7f;

	square(Y2, out->Y);
	mult(dY2, d, Y2);
	sub(Y2_1, Y2, one);
	add(dY2_1, dY2, one);
	recip(_1_dY2_1, dY2_1);
	mult(X2, Y2_1, _1_dY2_1);

	if (!square_root(X, X2))
		return 0;

	/* No squeeze is necessary after subtractions from zero if the subtrahend is squeezed */
	sub(Xt, zero, X);

	select(out->X, X, Xt, (in->p[31] >> 7) ^ parity(X));

	mult(out->T, out->X, out->Y);

	return 1;
}

int ecc_25519_load_packed_legacy(ecc_25519_work_t *out, const ecc_int256_t *in) {
	int i;
	uint32_t X2[32] /* X^2 */, aX2[32] /* aX^2 */, dX2[32] /* dX^2 */, _1_aX2[32] /* 1-aX^2 */, _1_dX2[32] /* 1-aX^2 */;
	uint32_t _1_1_dX2[32]  /* 1/(1-aX^2) */, Y2[32] /* Y^2 */, Y[32], Yt[32], X_legacy[32];

	for (i = 0; i < 32; i++) {
		X_legacy[i] = in->p[i];
		out->Z[i] = (i == 0);
	}

	X_legacy[31] &= 0x7f;

	square(X2, X_legacy);
	mult_int(aX2, UINT32_C(486664), X2);
	mult_int(dX2, UINT32_C(486660), X2);
	sub(_1_aX2, one, aX2);
	sub(_1_dX2, one, dX2);
	recip(_1_1_dX2, _1_dX2);
	mult(Y2, _1_aX2, _1_1_dX2);

	if (!square_root(Y, Y2))
		return 0;

	/* No squeeze is necessary after subtractions from zero if the subtrahend is squeezed */
	sub(Yt, zero, Y);

	select(out->Y, Y, Yt, (in->p[31] >> 7) ^ parity(Y));

	mult(out->X, X_legacy, legacy_to_ed25519);
	mult(out->T, out->X, out->Y);

	return 1;
}

int ecc_25519_load_packed(ecc_25519_work_t *out, const ecc_int256_t *in) {
	return ecc_25519_load_packed_legacy(out, in);
}


void ecc_25519_store_packed_ed25519(ecc_int256_t *out, const ecc_25519_work_t *in) {
	ecc_int256_t x;

	ecc_25519_store_xy_ed25519(&x, out, in);
	out->p[31] |= (x.p[0] << 7);
}

void ecc_25519_store_packed_legacy(ecc_int256_t *out, const ecc_25519_work_t *in) {
	ecc_int256_t y;

	ecc_25519_store_xy_legacy(out, &y, in);
	out->p[31] |= (y.p[0] << 7);
}

void ecc_25519_store_packed(ecc_int256_t *out, const ecc_25519_work_t *in) {
	ecc_25519_store_packed_legacy(out, in);
}


int ecc_25519_is_identity(const ecc_25519_work_t *in) {
	uint32_t Y_Z[32];

	sub(Y_Z, in->Y, in->Z);
	squeeze(Y_Z);

	return (check_zero(in->X)&check_zero(Y_Z));
}

void ecc_25519_negate(ecc_25519_work_t *out, const ecc_25519_work_t *in) {
	int i;

	for (i = 0; i < 32; i++) {
		out->Y[i] = in->Y[i];
		out->Z[i] = in->Z[i];
	}

	/* No squeeze is necessary after subtractions from zero if the subtrahend is squeezed */
	sub(out->X, zero, in->X);
	sub(out->T, zero, in->T);
}

void ecc_25519_double(ecc_25519_work_t *out, const ecc_25519_work_t *in) {
	uint32_t A[32], B[32], C[32], D[32], E[32], F[32], G[32], H[32], t0[32], t1[32];

	square(A, in->X);

	square(B, in->Y);

	square(t0, in->Z);
	mult_int(C, 2, t0);

	sub(D, zero, A);

	add(t0, in->X, in->Y);
	square(t1, t0);
	sub(t0, t1, A);
	sub(E, t0, B);

	add(G, D, B);
	sub(F, G, C);
	sub(H, D, B);

	mult(out->X, E, F);
	mult(out->Y, G, H);
	mult(out->T, E, H);
	mult(out->Z, F, G);
}

void ecc_25519_add(ecc_25519_work_t *out, const ecc_25519_work_t *in1, const ecc_25519_work_t *in2) {
	const uint32_t j = UINT32_C(60833);
	const uint32_t k = UINT32_C(121665);
	uint32_t A[32], B[32], C[32], D[32], E[32], F[32], G[32], H[32], t0[32], t1[32];

	sub(t0, in1->Y, in1->X);
	mult_int(t1, j, t0);
	sub(t0, in2->Y, in2->X);
	mult(A, t0, t1);

	add(t0, in1->Y, in1->X);
	mult_int(t1, j, t0);
	add(t0, in2->Y, in2->X);
	mult(B, t0, t1);

	mult_int(t0, k, in2->T);
	mult(C, in1->T, t0);

	mult_int(t0, 2*j, in2->Z);
	mult(D, in1->Z, t0);

	sub(E, B, A);
	add(F, D, C);
	sub(G, D, C);
	add(H, B, A);

	mult(out->X, E, F);
	mult(out->Y, G, H);
	mult(out->T, E, H);
	mult(out->Z, F, G);
}

/** Adds two points of the Elliptic Curve, assuming that in2->Z == 1 */
static void ecc_25519_add1(ecc_25519_work_t *out, const ecc_25519_work_t *in1, const ecc_25519_work_t *in2) {
	const uint32_t j = UINT32_C(60833);
	const uint32_t k = UINT32_C(121665);
	uint32_t A[32], B[32], C[32], D[32], E[32], F[32], G[32], H[32], t0[32], t1[32];

	sub(t0, in1->Y, in1->X);
	mult_int(t1, j, t0);
	sub(t0, in2->Y, in2->X);
	mult(A, t0, t1);

	add(t0, in1->Y, in1->X);
	mult_int(t1, j, t0);
	add(t0, in2->Y, in2->X);
	mult(B, t0, t1);

	mult_int(t0, k, in2->T);
	mult(C, in1->T, t0);

	mult_int(D, 2*j, in1->Z);

	sub(E, B, A);
	add(F, D, C);
	sub(G, D, C);
	add(H, B, A);

	mult(out->X, E, F);
	mult(out->Y, G, H);
	mult(out->T, E, H);
	mult(out->Z, F, G);
}

void ecc_25519_sub(ecc_25519_work_t *out, const ecc_25519_work_t *in1, const ecc_25519_work_t *in2) {
	ecc_25519_work_t in2_neg;

	ecc_25519_negate(&in2_neg, in2);
	ecc_25519_add(out, in1, &in2_neg);
}

void ecc_25519_scalarmult_bits(ecc_25519_work_t *out, const ecc_int256_t *n, const ecc_25519_work_t *base, unsigned bits) {
	ecc_25519_work_t Q2, Q2p;
	ecc_25519_work_t cur = ecc_25519_work_identity;
	int b, pos;

	if (bits > 256)
		bits = 256;

	for (pos = bits - 1; pos >= 0; --pos) {
		b = n->p[pos / 8] >> (pos & 7);
		b &= 1;

		ecc_25519_double(&Q2, &cur);
		ecc_25519_add(&Q2p, &Q2, base);
		selectw(&cur, &Q2, &Q2p, b);
	}

	*out = cur;
}

void ecc_25519_scalarmult(ecc_25519_work_t *out, const ecc_int256_t *n, const ecc_25519_work_t *base) {
	ecc_25519_scalarmult_bits(out, n, base, 256);
}

void ecc_25519_scalarmult_base_bits(ecc_25519_work_t *out, const ecc_int256_t *n, unsigned bits) {
	ecc_25519_work_t Q2, Q2p;
	ecc_25519_work_t cur = ecc_25519_work_identity;
	int b, pos;

	if (bits > 256)
		bits = 256;

	for (pos = bits - 1; pos >= 0; --pos) {
		b = n->p[pos / 8] >> (pos & 7);
		b &= 1;

		ecc_25519_double(&Q2, &cur);
		ecc_25519_add1(&Q2p, &Q2, &ecc_25519_work_default_base);
		selectw(&cur, &Q2, &Q2p, b);
	}

	*out = cur;
}

void ecc_25519_scalarmult_base(ecc_25519_work_t *out, const ecc_int256_t *n) {
	ecc_25519_scalarmult_base_bits(out, n, 256);
}

