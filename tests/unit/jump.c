// tests/unit/jump.c
//
// Unit tests for the cromulent_jump functionality
// Tests that jumping ahead in the sequence produces the expected results
// and that jump operations provide proper stream separation.

#include "cromulent.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// For simplicity, define a check macro that prints error info
#define CHECK(cond, msg) do { \
    if (!(cond)) { \
        fprintf(stderr, "FAIL: %s at line %d: %s\n", __FILE__, __LINE__, msg); \
        return 1; \
    } \
} while (0)

// Test that jump actually advances the sequence
int test_jump_advance() {
    printf("Testing jump advances the sequence... ");
    
    // Initialize two states with the same seed
    cromulent_state st1, st2;
    cromulent_init(&st1, 0x123456789ABCDEF0ULL);
    cromulent_init(&st2, 0x123456789ABCDEF0ULL);
    
    // Compare initial values to confirm they start at the same point
    uint64_t initial1 = cromulent_next(&st1);
    uint64_t initial2 = cromulent_next(&st2);
    CHECK(initial1 == initial2, "Initial values should match");
    
    // Jump ahead with st1
    cromulent_jump(&st1);
    
    // Generate single value from st1 after jump
    uint64_t after_jump = cromulent_next(&st1);
    
    // Generate multiple values from st2 without jumping
    int match_found = 0;
    for (int i = 0; i < 10000; i++) {
        uint64_t regular_val = cromulent_next(&st2);
        if (regular_val == after_jump) {
            match_found = 1;
            break;
        }
    }
    
    // We don't expect to find a match in a small number of iterations
    // since jump should advance by 2^64 steps
    CHECK(!match_found, "Jump should advance far beyond regular iteration");
    
    printf("OK\n");
    return 0;
}

// Test that two states with the same seed but different jump counts
// produce different sequences (stream separation)
int test_stream_separation() {
    printf("Testing stream separation with jump... ");
    
    // Create two states with the same seed
    cromulent_state st1, st2;
    cromulent_init(&st1, 0xFEDCBA9876543210ULL);
    cromulent_init(&st2, 0xFEDCBA9876543210ULL);
    
    // Jump one of them ahead
    cromulent_jump(&st1);
    
    // Generate sequences from both and ensure they differ
    int differences = 0;
    for (int i = 0; i < 100; i++) {
        uint64_t val1 = cromulent_next(&st1);
        uint64_t val2 = cromulent_next(&st2);
        if (val1 != val2) {
            differences++;
        }
    }
    
    // We expect all values to be different after a jump
    CHECK(differences == 100, "All values should differ after jump");
    
    printf("OK\n");
    return 0;
}

// Test multiple jumps to check for any issues with repeated jumping
int test_multiple_jumps() {
    printf("Testing multiple jumps... ");
    
    cromulent_state st;
    cromulent_init(&st, 0xA5A5A5A5A5A5A5A5ULL);
    
    // Values after multiple jumps should be different
    uint64_t values[5];
    
    // Get initial value
    values[0] = cromulent_next(&st);
    
    // Get values after successive jumps
    for (int i = 1; i < 5; i++) {
        cromulent_jump(&st);
        values[i] = cromulent_next(&st);
    }
    
    // Check that all values are different from each other
    for (int i = 0; i < 5; i++) {
        for (int j = i + 1; j < 5; j++) {
            CHECK(values[i] != values[j], "Values after different jumps should differ");
        }
    }
    
    printf("OK\n");
    return 0;
}

// Test idempotence of jumping from the same starting point
int test_jump_idempotence() {
    printf("Testing jump idempotence... ");
    
    // Create two states with the same seed
    cromulent_state st1, st2;
    cromulent_init(&st1, 0x0123456789ABCDEFULL);
    cromulent_init(&st2, 0x0123456789ABCDEFULL);
    
    // Jump both states once
    cromulent_jump(&st1);
    cromulent_jump(&st2);
    
    // Compare sequences after jumping
    for (int i = 0; i < 100; i++) {
        uint64_t val1 = cromulent_next(&st1);
        uint64_t val2 = cromulent_next(&st2);
        CHECK(val1 == val2, "Same jumps from same seed should produce identical sequences");
    }
    
    printf("OK\n");
    return 0;
}

int main() {
    printf("Running Cromulent PRNG jump tests\n");
    
    int result = 0;
    result |= test_jump_advance();
    result |= test_stream_separation();
    result |= test_multiple_jumps();
    result |= test_jump_idempotence();
    
    if (result == 0) {
        printf("All jump tests passed successfully!\n");
        return 0;
    } else {
        printf("Some tests failed!\n");
        return 1;
    }
}
