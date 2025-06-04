// tests/unit/load.c
//
// Unit tests for the cromulent_load functionality
// Tests that loading a saved PRNG state correctly restores the generator
// and produces the expected sequence.

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

// Test basic load functionality
int test_load_basic() {
    printf("Testing basic load functionality... ");
    
    cromulent_state st_original, st_loaded;
    cromulent_init(&st_original, 0xDEADBEEFCAFEBABEULL);
    
    // Save the original state
    uint8_t buffer[16];
    cromulent_save(&st_original, buffer);
    
    // Initialize loaded state with a different seed
    cromulent_init(&st_loaded, 0x0000000000000000ULL);
    
    // Load the saved state
    cromulent_load(&st_loaded, buffer);
    
    // Check internal state values match
    CHECK(st_loaded.s0 == st_original.s0, "Loaded s0 should match original s0");
    CHECK(st_loaded.s1 == st_original.s1, "Loaded s1 should match original s1");
    
    printf("OK\n");
    return 0;
}

// Test that loaded state produces the same sequence as original
int test_load_sequence() {
    printf("Testing loaded state produces same sequence... ");
    
    cromulent_state st_original, st_loaded;
    cromulent_init(&st_original, 0x9876543210ABCDEFULL);
    
    // Save the original state
    uint8_t buffer[16];
    cromulent_save(&st_original, buffer);
    
    // Initialize loaded state
    cromulent_init(&st_loaded, 0x0000000000000000ULL);
    cromulent_load(&st_loaded, buffer);
    
    // Generate and compare sequences
    for (int i = 0; i < 1000; i++) {
        uint64_t val_original = cromulent_next(&st_original);
        uint64_t val_loaded = cromulent_next(&st_loaded);
        
        CHECK(val_original == val_loaded, 
              "Loaded state should produce identical sequence to original");
    }
    
    printf("OK\n");
    return 0;
}

// Test loading after generating some values
int test_load_after_generation() {
    printf("Testing load after generation... ");
    
    cromulent_state st1, st2;
    cromulent_init(&st1, 0xABCDEF0123456789ULL);
    
    // Generate some values
    for (int i = 0; i < 10; i++) {
        cromulent_next(&st1);
    }
    
    // Save the state
    uint8_t buffer[16];
    cromulent_save(&st1, buffer);
    
    // Initialize a new state and load
    cromulent_init(&st2, 0x0000000000000000ULL);
    cromulent_load(&st2, buffer);
    
    // Generate and compare sequences
    for (int i = 0; i < 100; i++) {
        uint64_t val1 = cromulent_next(&st1);
        uint64_t val2 = cromulent_next(&st2);
        
        CHECK(val1 == val2, "States should produce identical sequences after loading mid-stream");
    }
    
    printf("OK\n");
    return 0;
}

// Test loading after jumping
int test_load_after_jump() {
    printf("Testing load after jump... ");
    
    cromulent_state st1, st2;
    cromulent_init(&st1, 0x0123456789ABCDEFULL);
    
    // Jump ahead
    cromulent_jump(&st1);
    
    // Save the state
    uint8_t buffer[16];
    cromulent_save(&st1, buffer);
    
    // Initialize a new state and load
    cromulent_init(&st2, 0xFFFFFFFFFFFFFFFFULL);
    cromulent_load(&st2, buffer);
    
    // Generate and compare sequences
    for (int i = 0; i < 100; i++) {
        uint64_t val1 = cromulent_next(&st1);
        uint64_t val2 = cromulent_next(&st2);
        
        CHECK(val1 == val2, "States should produce identical sequences after loading jumped state");
    }
    
    printf("OK\n");
    return 0;
}

// Test repeated save and load cycles
int test_multiple_save_load() {
    printf("Testing multiple save/load cycles... ");
    
    cromulent_state st1, st2;
    cromulent_init(&st1, 0x5A5A5A5A5A5A5A5AULL);
    
    // Generate 10 values
    for (int i = 0; i < 10; i++) {
        cromulent_next(&st1);
    }
    
    // Multiple save/load cycles
    for (int cycle = 0; cycle < 5; cycle++) {
        // Save state
        uint8_t buffer[16];
        cromulent_save(&st1, buffer);
        
        // Load into different state
        cromulent_init(&st2, 0);
        cromulent_load(&st2, buffer);
        
        // Check next value matches
        uint64_t val1 = cromulent_next(&st1);
        uint64_t val2 = cromulent_next(&st2);
        
        CHECK(val1 == val2, "States should match after each save/load cycle");
        
        // Generate a few more values
        for (int i = 0; i < 5; i++) {
            cromulent_next(&st1);
        }
    }
    
    printf("OK\n");
    return 0;
}

// Test loading corrupt or invalid data
int test_load_robustness() {
    printf("Testing load robustness... ");
    
    cromulent_state st_original, st_loaded;
    cromulent_init(&st_original, 0xF0F0F0F0F0F0F0F0ULL);
    
    // Generate a reference value
    cromulent_next(&st_original); // advance state
    
    // Create and manipulate buffer
    uint8_t buffer[16] = {0};
    
    // Try loading all zeros
    cromulent_init(&st_loaded, 0x1111111111111111ULL);
    cromulent_load(&st_loaded, buffer);
    
    // State should be loaded as zeros, but the generator should still function
    uint64_t val = cromulent_next(&st_loaded);
    (void)val; // ensure call succeeds even with zero state
    
    // Set buffer to known pattern and verify loading works
    for (int i = 0; i < 16; i++) {
        buffer[i] = (uint8_t)i;
    }
    
    cromulent_load(&st_loaded, buffer);
    uint64_t val1 = cromulent_next(&st_loaded);
    
    // Load again and verify same output
    cromulent_load(&st_loaded, buffer);
    uint64_t val2 = cromulent_next(&st_loaded);
    
    CHECK(val1 == val2, "Same loaded state should produce same outputs");
    
    printf("OK\n");
    return 0;
}

int main() {
    printf("Running Cromulent PRNG load tests\n");
    
    int result = 0;
    result |= test_load_basic();
    result |= test_load_sequence();
    result |= test_load_after_generation();
    result |= test_load_after_jump();
    result |= test_multiple_save_load();
    result |= test_load_robustness();
    
    if (result == 0) {
        printf("All load tests passed successfully!\n");
        return 0;
    } else {
        printf("Some tests failed!\n");
        return 1;
    }
}
