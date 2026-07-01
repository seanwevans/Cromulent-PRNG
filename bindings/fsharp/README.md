# Cromulent PRNG — F#

A dependency-free F# port of the scalar Cromulent generator. `CromulentEngine`
reproduces the C reference stream (`cromulent_init` / `cromulent_next`)
bit-for-bit; `StrongEngine` mirrors the heavier `cromulent_strong` variant.
Uses native `uint64`, `BitOperations.RotateLeft`, and `Math.BigMul` for the
unbiased `Bounded` (Lemire's method).

```fsharp
open Cromulent

let rng = CromulentEngine(0x0123456789ABCDEFUL)
let x = rng.NextUInt64()
let d = rng.NextDouble()   // [0, 1)
let r = rng.Bounded(6UL)   // unbiased [0, 6)
```

## Test

```bash
dotnet run -c Release
```
