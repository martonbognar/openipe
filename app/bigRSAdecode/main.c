#include <msp430.h>
#include <stddef.h>
#include <string.h>
#include <stdbool.h>

#include "libipe/ipe_support.h"
#include "libipe/sim_io.h"

#include "../customTLS/crypto.h"


DECLARE_IPE_STRUCT;

#define TEXT_SIZE 5
#define KEY_SIZE 64


RSA_CTX IPE_VAR rsa_ctx;


void IPE_ENTRY init_rsa(){    
    BI_CTX* ctx = bi_initialize();

    uint8_t n[KEY_SIZE] = {
        0xc4,0xf8,0x6c,0x3f,0xe5,0x01,0x09,0x0a,0x40,0xe0,0x48,0x3e,0x02,0x6b,
        0xda,0x82,0x42,0xbd,0xe7,0x98,0xb9,0xfc,0x19,0xc4,0x99,0xb2,0x2d,0x4a,0x14,
        0x82,0x0a,0xe0,0xb8,0x44,0x80,0x62,0xd6,0x92,0xcc,0x71,0xf7,0xb3,0x1e,0x2d,
        0x70,0x65,0xd5,0xd7,0x77,0xc5,0xf6,0x39,0xdc,0x44,0xf2,0xcc,0x84,0x12,0x3d,
        0x7c,0xfa,0x76,0x79,0x81
    };

    uint8_t e[3] = {0x01, 0x00, 0x01};

    uint8_t d[KEY_SIZE] = {
        0xb5,0x7d,0xfe,0x28,0xa5,0xb7,0x5d,0x80,0x10,0x25,0x59,0x0b,0xa2,0x29,
        0x85,0x0e,0xcf,0xb6,0xb2,0x46,0xdc,0xe0,0x79,0x51,0xd9,0x18,0xff,0x78,0x2a,
        0x0b,0x65,0x3e,0xea,0x48,0x70,0x2e,0xb7,0xdc,0xca,0x50,0xaf,0xb1,0x15,0x18,
        0xaf,0x5b,0x3b,0x4b,0x61,0x4a,0xcd,0x41,0x9d,0x23,0x2d,0xef,0x1d,0x0a,0xaf,
        0xb3,0x27,0x48,0xbb,0x11
    };

    bigint* bi_n = bi_import(ctx, n, KEY_SIZE);
    bigint* bi_e = bi_import(ctx, e, 3);
    bigint* bi_d = bi_import(ctx, d, KEY_SIZE);

    IPE_ASSERT((bi_n != NULL) && (bi_e != NULL) && (bi_d != NULL), "[*] Testing big parameters");

    rsa_ctx.bi_ctx = ctx;
    rsa_ctx.d = bi_d;
    rsa_ctx.e = bi_e;
    rsa_ctx.m = bi_n;

    bi_set_mod(rsa_ctx.bi_ctx, rsa_ctx.m, BIGINT_M_OFFSET);
}


void IPE_ENTRY rsa_encrypt(const uint16_t *in_data, bigint** out_data, int out_len){
    for(int i = 0; i < out_len; i++){
        bigint* in_m = int_to_bi(rsa_ctx.bi_ctx, in_data[i]);   
        out_data[i] = bi_mod_power(rsa_ctx.bi_ctx, in_m, rsa_ctx.e);

        bi_free(rsa_ctx.bi_ctx, in_m);
    }
}


void IPE_ENTRY rsa_decrypt(bigint** in_data, uint16_t *out_data, int out_len){
    for(int i = 0; i < out_len; i++){
        bigint* conv = bi_mod_power(rsa_ctx.bi_ctx, in_data[i], rsa_ctx.d);
        out_data[i] = conv->comps[0];

        bi_free(rsa_ctx.bi_ctx, conv);
    }
}

void IPE_ENTRY init_heap(){
    initialise_heap();
}


int main(){
    WDTCTL = WDTPW | WDTHOLD; // Stop Watchdog
    init_heap();
  
    bigint* cipher_text[TEXT_SIZE];
    uint16_t dechiper_text[TEXT_SIZE];
    uint16_t plain_text[TEXT_SIZE] = {'H', 'e', 'l', 'l', 'o'};

    init_rsa();

    int how_much_to_decrypt = 1;
    rsa_encrypt(
        plain_text, 
        cipher_text, 
        how_much_to_decrypt
    );

    puts("[*] Finished encryption");

    rsa_decrypt(
        cipher_text, 
        dechiper_text, 
        how_much_to_decrypt
    );

    ASSERT(memcmp(plain_text, dechiper_text, how_much_to_decrypt) == 0, "[*] Check RSA result");
    PASS();
}
