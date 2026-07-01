# Cromulent PRNG — Rust

A `#![no_std]`, dependency-free Rust port of the scalar Cromulent generator. The
`Engine` reproduces the C reference stream (`cromulent_init` / `cromulent_next`)
bit-for-bit; `StrongEngine` mirrors the heavier `cromulent_strong` variant. Both
implement `Iterator<Item = u64>`.

```rust
use cromulent::Engine;

let mut rng = Engine::new(0x0123456789ABCDEF);
let x: u64 = rng.next_u64();
let d: f64 = rng.next_f64();     // [0, 1)
let r: u64 = rng.bounded(6);     // unbiased [0, 6)
```

## Test

```bash
cargo test
```
