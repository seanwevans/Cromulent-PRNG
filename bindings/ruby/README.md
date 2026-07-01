# Cromulent PRNG — Ruby

A pure-Ruby port of the scalar Cromulent generator (no dependencies).
`Cromulent::Engine` reproduces the C reference stream (`cromulent_init` /
`cromulent_next`) bit-for-bit; `Cromulent::StrongEngine` mirrors the heavier
`cromulent_strong` variant. Ruby's arbitrary-precision integers are masked to
64 bits to reproduce the wrapping behavior of the C generator.

```ruby
require_relative "lib/cromulent"

rng = Cromulent::Engine.new(0x0123456789ABCDEF)
rng.next_u64      # 64-bit integer
rng.next_float    # [0, 1)
rng.bounded(6)    # unbiased [0, 6)
```

## Test

```bash
ruby test/test_cromulent.rb
```
