# Cromulent PRNG — Haskell

A dependency-free Haskell port of the scalar Cromulent generator. The engines
are pure: each step returns the output together with the next state.
`Engine` reproduces the C reference stream (`cromulent_init` / `cromulent_next`)
bit-for-bit; `StrongEngine` mirrors the heavier `cromulent_strong` variant.
`Word64` arithmetic is modular, matching the C generator.

```haskell
import Cromulent

let e0 = mkEngine 0x0123456789ABCDEF
    (x, e1) = next e0          -- 64-bit output + next engine
    (d, e2) = nextDouble e1    -- [0, 1)
    (r, e3) = bounded 6 e2     -- unbiased [0, 6)
```

## Test

Uses only `base`, so no build tool is needed:

```bash
runghc -isrc test/Spec.hs
```
