// tests/unit/range.c
//
// Unit test for the cromulent_range functionality when n == 0

#include "cromulent.h"
#include <stdio.h>

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
    return 0;
}

