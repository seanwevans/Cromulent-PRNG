# Cromulent PRNG — Nim

A dependency-free Nim port of the scalar Cromulent generator. `CromulentEngine`
reproduces the C reference stream (`cromulent_init` / `cromulent_next`)
bit-for-bit; `StrongEngine` mirrors the heavier `cromulent_strong` variant.
Nim's `uint64` wraps on overflow, matching the C generator.

```nim
import cromulent

var rng = initEngine(0x0123456789ABCDEF'u64)
discard rng.next        # 64-bit output
echo rng.nextFloat      # [0, 1)
echo rng.bounded(6'u64) # unbiased [0, 6)
```

## Test

```bash
nim c -r tests/test_cromulent.nim
# or: nimble test
```
