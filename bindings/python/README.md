# Cromulent PRNG — Python

A pure-Python port of the scalar Cromulent generator (no dependencies).
`Engine` reproduces the C reference stream (`cromulent_init` / `cromulent_next`)
bit-for-bit; `StrongEngine` mirrors the heavier `cromulent_strong` variant.

```python
from cromulent import Engine

rng = Engine(0x0123456789ABCDEF)
x = rng.next_u64()       # 64-bit int
d = rng.random()         # [0, 1)
r = rng.bounded(6)       # unbiased [0, 6)
```

## Test

```bash
python -m unittest
```
