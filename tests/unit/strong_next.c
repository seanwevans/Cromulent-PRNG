// tests/unit/strong_next.c
//
// Unit tests for the cromulent_strong_next functionality
// Verifies initialization and output behavior for the "strong" variant.

#include "cromulent.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// cromulent_strong_next is not declared in the public header
extern uint64_t cromulent_strong_next(cromulent_strong_state *state);

// For simplicity, define a check macro that prints error info
#define CHECK(cond, msg) do { \
    if (!(cond)) { \
        fprintf(stderr, "FAIL: %s at line %d: %s\n", __FILE__, __LINE__, msg); \
        return 1; \
    } \
} while (0)

// Test that two states initialized with the same seed
// produce the same sequence of outputs
int test_same_seed_reproducible() {
    printf("Testing reproducibility with same seed... ");

    cromulent_strong_state st1, st2;
    cromulent_strong_init(&st1, 0xDEADBEEFULL);
    cromulent_strong_init(&st2, 0xDEADBEEFULL);

    for (int i = 0; i < 10; i++) {
        uint64_t a = cromulent_strong_next(&st1);
        uint64_t b = cromulent_strong_next(&st2);
        CHECK(a == b, "Outputs should match for identical seeds");
    }

    printf("OK\n");
    return 0;
}

// Test that a known seed produces a specific sequence
int test_known_sequence() {
    printf("Testing output against known sequence... ");

    cromulent_strong_state st;
    cromulent_strong_init(&st, 0x1234567890ABCDEFULL);

    const uint64_t expected[] = {
        0x48c8d4b3efd623eeULL,
        0x79e31f9d464a6b45ULL,
        0x24e99692ea34b956ULL,
        0xbfcbc0d400dd7c4aULL,
        0xac9cd7d5e815d433ULL,
    };

    for (int i = 0; i < 5; i++) {
        uint64_t val = cromulent_strong_next(&st);
        CHECK(val == expected[i], "Output does not match expected value");
    }

    printf("OK\n");
    return 0;
}

int main() {
    printf("Running Cromulent strong_next tests\n");

    int result = 0;
    result |= test_same_seed_reproducible();
    result |= test_known_sequence();

    if (result == 0) {
        printf("All strong_next tests passed successfully!\n");
        return 0;
    } else {
        printf("Some tests failed!\n");
        return 1;
    }
}

