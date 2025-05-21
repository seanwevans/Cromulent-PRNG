<img src="assets/cromulent.jpg" height="100px">
# Cromulent PRNG

A modern Pseudo-Random Number Generator (PRNG) implemented in C.
`PractRand` 64TB test results [here](tests/results/practrand64TB.txt)

## Overview

Cromulent PRNG is a portable C library providing a high-quality random number generation algorithm with a focus on performance, statistical quality, and ease of use. The library includes both scalar implementations for general use and SIMD-accelerated variants for x86_64 platforms with AVX2 support.

## Features

- High-performance `cromulent128` PRNG with 128-bit state
- Optimized implementations:
  - Scalar code for all platforms
  - AVX2-accelerated implementation for x86_64 platforms

- Comprehensive API:
  - Basic operations: initialization, next value
  - Utilities: uniform doubles/floats, bounded ranges
  - State management: save/load for reproducibility
  - Jump-ahead functionality for stream separation

- Built-in benchmarking and testing tools
- Small footprint with minimal dependencies

## Requirements

- C11 compatible compiler
- CMake 3.19 or higher
- (Optional) AVX2 support for SIMD acceleration

## Building

```bash
mkdir build && cd build
cmake ..
make
```

For optimized builds:

```bash
cmake -DCMAKE_BUILD_TYPE=Release ..
make
```

## Installation

```bash
sudo make install
```

This will install the library and headers to your system.

## Usage

### Basic Example

```c
#include "cromulent.h"
#include <stdio.h>

int main() {
    // Initialize the PRNG with a seed
    cromulent_state state;
    cromulent_init(&state, 12345);
    
    // Generate and print 10 random numbers
    for (int i = 0; i < 10; i++) {
        printf("%lu\n", cromulent_next(&state));
    }
    
    // Generate a random double in [0, 1)
    double rand_double = cromulent_double(&state);
    printf("Random double: %f\n", rand_double);
    
    // Generate a random integer in range [0, 99]
    uint64_t rand_range = cromulent_range(&state, 100);
    printf("Random in range [0, 99]: %lu\n", rand_range);
    
    return 0;
}
```

### Saving and Loading State

```c
// Save the current state
uint8_t buffer[16];  // cromulent128 state is 16 bytes
cromulent_save(&state, buffer);

// ... later or in another program ...

// Restore the state
cromulent_load(&state, buffer);
// Continue generating the same sequence from this point
```

### Using the Generator Registry

The library maintains a registry system primarily for internal benchmarking and testing, but it can also be used in applications:

```c
// Get a reference to the Cromulent PRNG
const CromulentPRNG *gen = cromulent_registry_find("cromulent128");
if (gen) {
    gen->init(12345);
    uint64_t random_value = gen->next();
}
```

## Benchmark Results

The library includes a micro-benchmark tool (`bench_micro`) that measures the performance of the cromulent128 PRNG algorithm. Here's a sample of expected performance on a modern CPU:

```
running 10000000000 samples with seed 69420
xoshiro256     : 4.00 ns/sample, dummy=15115886174096218845
cromulent128   : 2.93 ns/sample, dummy=8577353182525494841
splitmix64     : 1.27 ns/sample, dummy=12147880745723112187
pcg64          : 1.76 ns/sample, dummy=13280616445415795540
```

Exact numbers will vary based on your hardware.

## Testing

The library includes a basic sanity test suite. Run it with:

```bash
make test
```

## Design Philosophy

Cromulent PRNG aims to provide:

1. **Speed**: Optimized for modern CPUs with careful attention to instruction-level parallelism
2. **Quality**: All generators pass stringent statistical tests
3. **Simplicity**: Clean API with minimal dependencies
4. **Portability**: Works across platforms while taking advantage of hardware acceleration when available

## Technical Details

### State Size and Period

- `cromulent128`: 128-bit state (2 × 64-bit words), period approximately 2^128

### Output Mixing

The generator uses a carefully designed output mixing function to improve statistical distribution and quality, especially for low-order bits.

### Jump Operations

The library supports jump-ahead operations, allowing you to efficiently advance the state by 2^64 steps. This is useful for creating independent, non-overlapping streams for parallel applications.
