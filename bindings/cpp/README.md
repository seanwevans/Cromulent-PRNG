# Cromulent PRNG — C++

A header-only C++17 port of the scalar Cromulent generator
(`include/cromulent.hpp`). `cromulent::engine` models the standard
`UniformRandomBitGenerator` / `RandomNumberEngine` requirements, so it drops
directly into `<random>` distributions and `<algorithm>`. It reproduces the C
reference stream (`cromulent_init` / `cromulent_next`) bit-for-bit;
`cromulent::strong_engine` mirrors the heavier `cromulent_strong` variant.

```cpp
#include "cromulent.hpp"
#include <random>

cromulent::engine rng(0x0123456789ABCDEF);
std::uniform_int_distribution<int> die(1, 6);
int roll = die(rng);
double d = rng.next_double();   // [0, 1)
```

## Test

```bash
cmake -S . -B build && cmake --build build && ctest --test-dir build
```

The test links the C reference implementation (from `../../src`) and verifies
the C++ stream matches it exactly.
