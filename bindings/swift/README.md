# Cromulent PRNG — Swift

A dependency-free Swift port of the scalar Cromulent generator. `Engine`
reproduces the C reference stream (`cromulent_init` / `cromulent_next`)
bit-for-bit; `StrongEngine` mirrors the heavier `cromulent_strong` variant.
Uses native `UInt64` with the wrapping operators (`&+`, `&-`, `&*`) and
`multipliedFullWidth(by:)` for the unbiased `bounded` (Lemire's method).

```swift
var rng = Engine(seed: 0x0123456789ABCDEF)
let x = rng.next()          // UInt64
let d = rng.nextDouble()    // [0, 1)
let r = rng.bounded(6)      // unbiased [0, 6)
```

## Test

The executable target runs the self-test:

```bash
swift run
```
