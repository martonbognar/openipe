#include <msp430.h>
#include <stddef.h>
#include <string.h>
#include <stdbool.h>

#include "libipe/ipe_support.h"
#include "libipe/sim_io.h"
#include "libipe/ipe-step.h"

#include "../customTLS/crypto.h"


DECLARE_IPE_STRUCT;

#define TEXT_SIZE 5


bool IPE_VAR is_rsa_initialised = false;
RSA_CTX IPE_VAR rsa_ctx;
int IPE_VAR private_key = 4279; 


void IPE_ENTRY init_rsa(int n, int e, int d){    
    BI_CTX* ctx = bi_initialize();

    bigint* bi_n = int_to_bi(ctx, n);
    bigint* bi_e = int_to_bi(ctx, e);
    bigint* bi_d = int_to_bi(ctx, d);

    IPE_ASSERT((bi_n != NULL) && (bi_e != NULL) && (bi_d != NULL), "[*] Testing big parameters");

    rsa_ctx.bi_ctx = ctx;
    rsa_ctx.d = bi_d;
    rsa_ctx.e = bi_e;
    rsa_ctx.m = bi_n;
    rsa_ctx.num_octets = 1;

    bi_set_mod(rsa_ctx.bi_ctx, rsa_ctx.m, BIGINT_M_OFFSET);
    is_rsa_initialised = true;
}


void IPE_ENTRY rsa_decrypt(const uint16_t *in_data, uint16_t *out_data, int out_len){
    if(!is_rsa_initialised)
        init_rsa(5141, 7, private_key);

    for(int i = 0; i < out_len; i++){
        bigint* in_m = int_to_bi(rsa_ctx.bi_ctx, in_data[i]);   
        bigint* conv = bi_mod_power(rsa_ctx.bi_ctx, in_m, rsa_ctx.d);

        out_data[i] = conv->comps[0];

        bi_free(rsa_ctx.bi_ctx, in_m);
        bi_free(rsa_ctx.bi_ctx, conv);
    }
}

int main(){
    WDTCTL = WDTPW | WDTHOLD; // Stop Watchdog
    __enable_interrupt();

    uint16_t plain_text[TEXT_SIZE] = {'H', 'e', 'l', 'l', 'o'};

    uint16_t cipher_text[TEXT_SIZE] = {2571, 1640, 4527, 4527, 1858};
    uint16_t dechiper_text[TEXT_SIZE] = {65, 65, 65, 65, 65};

    init_ssteper();

    int how_much_to_decrypt = 1;
    rsa_decrypt(
        cipher_text, 
        dechiper_text, 
        how_much_to_decrypt
    );

    ASSERT(memcmp(plain_text, dechiper_text, how_much_to_decrypt) == 0, "[*] Check RSA result");
    PASS();
}
