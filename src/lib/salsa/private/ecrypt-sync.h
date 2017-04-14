/* ecrypt-sync.h */

#define ECRYPT_init            __ not_used __ /* produce error otherwise */
#define ECRYPT_keysetup        salsa20_keysetup
#define ECRYPT_ivsetup         salsa20_ivsetup
#define ECRYPT_encrypt_bytes   salsa20_anycrypt_bytes
#define ECRYPT_decrypt_bytes   __ not_used __
#define ECRYPT_keystream_bytes __ not_used __

#include "ecrypt-portable.h"

#define ECRYPT_NAME "Salsa20"    /* [edit] */ 
#define ECRYPT_PROFILE "S3___"

#define ECRYPT_MAXKEYSIZE 256                 /* [edit] */
#define ECRYPT_KEYSIZE(i) (128 + (i)*128)     /* [edit] */

#define ECRYPT_MAXIVSIZE 64                   /* [edit] */
#define ECRYPT_IVSIZE(i) (64 + (i)*64)        /* [edit] */

typedef struct
{
  u32 input[16]; /* could be compressed */
} ECRYPT_ctx;

void ECRYPT_keysetup(
  ECRYPT_ctx* ctx, 
  const u8* key, 
  u32 keysize,                /* Key size in bits. */ 
  u32 ivsize);                /* IV size in bits. */ 

void ECRYPT_ivsetup(
  ECRYPT_ctx* ctx, 
  const u8* iv);

void ECRYPT_encrypt_bytes(
  ECRYPT_ctx* ctx, 
  const u8* plaintext, 
  u8* ciphertext, 
  u32 msglen);                /* Message length in bytes. */ 
