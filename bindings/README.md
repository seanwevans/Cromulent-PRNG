# Cromulent PRNG — language bindings

Idiomatic, dependency-free ports of the scalar Cromulent generator. Every port
produces the **identical 64-bit stream** as the C reference implementation
(`cromulent_init` / `cromulent_next`) for a given seed, and each ships with a
self-test that asserts against the same reference vectors.

Reference vectors for seed `0x0123456789ABCDEF` (first eight outputs of the
primary engine):

```
0x8b0849848b39737d  0x829ecfb661e3a84d  0x6cfb2afb89b5dc83  0x8ad5c0d490669f95
0x8d4459e6318f2474  0xa0b907b845990f61  0x2143675f2f4ff1ec  0x38fff6f9c33c4f8f
```

Each port exposes the primary `Engine` and the heavier `StrongEngine`, plus
`bounded(n)` (unbiased, Lemire's method) and floating-point helpers.

| Language   | Directory               | Run tests                          |
|------------|-------------------------|------------------------------------|
| C++ (17)   | `../include/cromulent.hpp` | built via the top-level CMake (`test_cpp_engine`) |
| Rust       | `rust/`                 | `cargo test`                       |
| Go         | `go/`                   | `go test ./...`                    |
| Python     | `python/`               | `python -m unittest`               |
| JavaScript | `javascript/`           | `node --test`                      |
| Racket     | `racket/`               | `raco test cromulent.rkt`          |

## Notes

- **C++** is header-only (`include/cromulent.hpp`) and models the standard
  `UniformRandomBitGenerator` / `RandomNumberEngine` requirements, so it drops
  directly into `<random>` distributions and `<algorithm>`.
- **Rust** is `#![no_std]` and `#![forbid(unsafe_code)]`; the engines implement
  `Iterator<Item = u64>`.
- **Python**, **JavaScript**, and **Racket** use big-integer arithmetic masked
  to 64 bits to reproduce the wrapping behavior of the C generator.
