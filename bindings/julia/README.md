# Cromulent PRNG — Julia

A dependency-free Julia port of the scalar Cromulent generator. `Engine`
reproduces the C reference stream (`cromulent_init` / `cromulent_next`)
bit-for-bit; `StrongEngine` mirrors the heavier `cromulent_strong` variant.
`UInt64` arithmetic wraps at 2^64, matching the C generator, and `widemul`
provides the 128-bit product for `bounded!` (Lemire's method).

```julia
include("src/Cromulent.jl"); using .Cromulent

rng = Engine(0x0123456789ABCDEF)
next_u64!(rng)        # UInt64
next_double!(rng)     # [0, 1)
bounded!(rng, UInt64(6))  # unbiased [0, 6)
```

## Test

```bash
julia test/runtests.jl
```
