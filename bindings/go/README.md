# Cromulent PRNG — Go

A standard-library-only Go port of the scalar Cromulent generator. `Engine`
reproduces the C reference stream (`cromulent_init` / `cromulent_next`)
bit-for-bit; `StrongEngine` mirrors the heavier `cromulent_strong` variant.

```go
rng := cromulent.New(0x0123456789ABCDEF)
x := rng.Next()          // uint64
d := rng.Float64()       // [0, 1)
r := rng.Bounded(6)      // unbiased [0, 6)
```

## Test

```bash
go test ./...
```
