# Cromulent PRNG — Crystal

A dependency-free Crystal port of the scalar Cromulent generator.
`Cromulent::Engine` reproduces the C reference stream (`cromulent_init` /
`cromulent_next`) bit-for-bit; `Cromulent::StrongEngine` mirrors the heavier
`cromulent_strong` variant. Uses native `UInt64` with the wrapping operators
(`&+`, `&-`, `&*`) to match the C generator's mod-2^64 arithmetic.

```crystal
require "./src/cromulent"

rng = Cromulent::Engine.new(0x0123456789ABCDEF_u64)
rng.next_u64      # UInt64
rng.next_float    # [0, 1)
rng.bounded(6_u64) # unbiased [0, 6)
```

## Test

```bash
crystal spec
```
