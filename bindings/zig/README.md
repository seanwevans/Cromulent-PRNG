# Cromulent PRNG — Zig

A dependency-free Zig port of the scalar Cromulent generator. `Engine`
reproduces the C reference stream (`cromulent_init` / `cromulent_next`)
bit-for-bit; `StrongEngine` mirrors the heavier `cromulent_strong` variant.
Uses native `u64` with the wrapping operators (`+%`, `*%`, `-%`) and `u128`
for the `bounded` product (Lemire's method).

```zig
const cromulent = @import("cromulent.zig");

var rng = cromulent.Engine.init(0x0123456789ABCDEF);
const x = rng.next();          // u64
const d = rng.nextDouble();    // [0, 1)
const r = rng.bounded(6);      // unbiased [0, 6)
```

## Test

```bash
zig test cromulent.zig
```
