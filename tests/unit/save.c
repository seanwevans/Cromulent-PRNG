// tests/unit/save.c
//
// Unit tests for the cromulent_save functionality
// Tests that saving the PRNG state works correctly and
// captures the complete state necessary for reproduction.

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

// Test basic save functionality - ensure buffer contains expected values
int test_save_basic() {
    printf("Testing basic save functionality... ");
    
    cromulent_state st;
    cromulent_init(&st, 0x1234567890ABCDEFULL);
    
    // Save the state to a buffer
    uint8_t buffer[16];
    cromulent_save(&st, buffer);
    
    // Manually check the saved state against the internal state
    uint64_t saved_s0, saved_s1;
    memcpy(&saved_s0, buffer, sizeof(uint64_t));
    memcpy(&saved_s1, buffer + sizeof(uint64_t), sizeof(uint64_t));
    
    CHECK(saved_s0 == st.s0, "Saved s0 should match state s0");
    CHECK(saved_s1 == st.s1, "Saved s1 should match state s1");
    
    printf("OK\n");
    return 0;
}

// Test saving after generating several values
int test_save_after_generation() {
    printf("Testing save after generation... ");
    
    cromulent_state st;
    cromulent_init(&st, 0x0F0F0F0F0F0F0F0FULL);
    
    // Generate some values first to advance the state
    for (int i = 0; i < 10; i++) {
        cromulent_next(&st);
    }
    
    // Save the state
    uint8_t buffer[16];
    cromulent_save(&st, buffer);
    
    // Check saved values
    uint64_t saved_s0, saved_s1;
    memcpy(&saved_s0, buffer, sizeof(uint64_t));
    memcpy(&saved_s1, buffer + sizeof(uint64_t), sizeof(uint64_t));
    
    CHECK(saved_s0 == st.s0, "Saved s0 should match state s0 after generation");
    CHECK(saved_s1 == st.s1, "Saved s1 should match state s1 after generation");
    
    printf("OK\n");
    return 0;
}

// Test saving after jumping
int test_save_after_jump() {
    printf("Testing save after jump... ");
    
    cromulent_state st;
    cromulent_init(&st, 0xA1B2C3D4E5F67890ULL);
    
    // Jump ahead
    cromulent_jump(&st);
    
    // Save the state
    uint8_t buffer[16];
    cromulent_save(&st, buffer);
    
    // Check saved values
    uint64_t saved_s0, saved_s1;
    memcpy(&saved_s0, buffer, sizeof(uint64_t));
    memcpy(&saved_s1, buffer + sizeof(uint64_t), sizeof(uint64_t));
    
    CHECK(saved_s0 == st.s0, "Saved s0 should match state s0 after jump");
    CHECK(saved_s1 == st.s1, "Saved s1 should match state s1 after jump");
    
    printf("OK\n");
    return 0;
}

// Test saving multiple times from the same state
int test_save_consistency() {
    printf("Testing save consistency... ");
    
    cromulent_state st;
    cromulent_init(&st, 0x1122334455667788ULL);
    
    // Generate some values
    for (int i = 0; i < 5; i++) {
        cromulent_next(&st);
    }
    
    // Save the state twice
    uint8_t buffer1[16];
    uint8_t buffer2[16];
    
    cromulent_save(&st, buffer1);
    cromulent_save(&st, buffer2);
    
    // Compare the two buffers - they should be identical
    CHECK(memcmp(buffer1, buffer2, 16) == 0, "Multiple saves should produce identical buffers");
    
    printf("OK\n");
    return 0;
}

// Test save with different seeds
int test_save_different_seeds() {
    printf("Testing save with different seeds... ");
    
    cromulent_state st1, st2;
    cromulent_init(&st1, 0x1111111111111111ULL);
    cromulent_init(&st2, 0x2222222222222222ULL);
    
    // Save both states
    uint8_t buffer1[16];
    uint8_t buffer2[16];
    
    cromulent_save(&st1, buffer1);
    cromulent_save(&st2, buffer2);
    
    // Buffers should be different because seeds are different
    CHECK(memcmp(buffer1, buffer2, 16) != 0, "States with different seeds should produce different buffers");
    
    printf("OK\n");
    return 0;
}

int main() {
    printf("Running Cromulent PRNG save tests\n");
    
    int result = 0;
    result |= test_save_basic();
    result |= test_save_after_generation();
    result |= test_save_after_jump();
    result |= test_save_consistency();
    result |= test_save_different_seeds();
    
    if (result == 0) {
        printf("All save tests passed successfully!\n");
        return 0;
    } else {
        printf("Some tests failed!\n");
        return 1;
    }
}
