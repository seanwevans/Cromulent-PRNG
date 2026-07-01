# Cromulent PRNG — JavaScript

A dependency-free, BigInt-based ES-module port of the scalar Cromulent
generator. `Engine` reproduces the C reference stream (`cromulent_init` /
`cromulent_next`) bit-for-bit; `StrongEngine` mirrors the heavier
`cromulent_strong` variant.

```js
import { Engine } from "./cromulent.mjs";

const rng = new Engine(0x0123456789abcdefn);
const x = rng.nextU64();     // BigInt
const d = rng.nextDouble();  // [0, 1)
const r = rng.bounded(6n);   // unbiased [0n, 6n)
```

## Test

```bash
node --test
```
