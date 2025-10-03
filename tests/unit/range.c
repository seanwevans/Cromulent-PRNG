// tests/unit/range.c
//
// Unit test for the cromulent_range functionality when n == 0

#include "cromulent.h"
#include <inttypes.h>
#include <stdio.h>

struct mul_case {
    uint64_t a;
    uint64_t b;
    uint64_t expected_hi;
    uint64_t expected_lo;
};

static const struct mul_case kMulCases[] = {
    {0x0000000000000000ULL, 0x0000000000000000ULL, 0x0000000000000000ULL, 0x0000000000000000ULL},
    {0x0000000000000001ULL, 0x0000000000000000ULL, 0x0000000000000000ULL, 0x0000000000000000ULL},
    {0xffffffffffffffffULL, 0xffffffffffffffffULL, 0xfffffffffffffffeULL, 0x0000000000000001ULL},
    {0x0000000100000001ULL, 0x0000000200000003ULL, 0x0000000000000002ULL, 0x0000000500000003ULL},
    {0x0123456789abcdefULL, 0xfedcba9876543210ULL, 0x0121fa00ad77d742ULL, 0x2236d88fe5618cf0ULL},
    {0x8000000000000000ULL, 0x0000000000000002ULL, 0x0000000000000001ULL, 0x0000000000000000ULL},
    {0x00000000ffffffffULL, 0xffffffff00000000ULL, 0x00000000fffffffeULL, 0x0000000100000000ULL},
    {0xaaaaaaaa55555555ULL, 0x0f0f0f0ff0f0f0f0ULL, 0x0a0a0a0a9b9b9b9aULL, 0xaaaaaaaaafafafb0ULL},
    {0xdeadbeefcafebabeULL, 0x1234567890abcdefULL, 0x0fd5bdeee268600eULL, 0x773285ae1c447d62ULL},
    {0x0000000000000001ULL, 0xffffffffffffffffULL, 0x0000000000000000ULL, 0xffffffffffffffffULL},
};

int main() {
    printf("Testing cromulent_range with n=0... ");

    cromulent_state st;
    cromulent_init(&st, 0x123456789ABCDEF0ULL);

    uint64_t val = cromulent_range(&st, 0);
    if (val != 0) {
        fprintf(stderr, "Expected 0, got %llu\n", (unsigned long long)val);
        return 1;
    }

    printf("OK\n");

    printf("Testing 64x64->128 fallback multiplication parity... ");
    for (size_t i = 0; i < sizeof(kMulCases) / sizeof(kMulCases[0]); ++i) {
        uint64_t hi_fallback = 0;
        uint64_t lo_fallback = 0;
        cromulent_mul_u64_fallback(kMulCases[i].a, kMulCases[i].b, &hi_fallback, &lo_fallback);

#ifdef __SIZEOF_INT128__
        __uint128_t product = (__uint128_t)kMulCases[i].a * (__uint128_t)kMulCases[i].b;
        uint64_t hi_native = (uint64_t)(product >> 64);
        uint64_t lo_native = (uint64_t)product;
#else
        uint64_t hi_native = kMulCases[i].expected_hi;
        uint64_t lo_native = kMulCases[i].expected_lo;
#endif

        if (hi_fallback != hi_native || lo_fallback != lo_native) {
            fprintf(stderr,
                    "Mismatch for case %zu: A=0x%016" PRIx64 ", B=0x%016" PRIx64
                    ", fallback=(0x%016" PRIx64 ", 0x%016" PRIx64 ") expected=(0x%016" PRIx64
                    ", 0x%016" PRIx64 ")\n",
                    i, kMulCases[i].a, kMulCases[i].b, hi_fallback, lo_fallback, hi_native, lo_native);
            return 1;
        }
    }
    printf("OK\n");

    return 0;
}

