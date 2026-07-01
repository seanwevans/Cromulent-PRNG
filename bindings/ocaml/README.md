# Cromulent PRNG — OCaml

A dependency-free OCaml port of the scalar Cromulent generator.
`make_engine` / `next` reproduce the C reference stream (`cromulent_init` /
`cromulent_next`) bit-for-bit; `make_strong_engine` / `strong_next` mirror the
heavier `cromulent_strong` variant. Uses `Int64` with `unsigned_compare` /
`unsigned_rem` for the unsigned parts.

```ocaml
let rng = Cromulent.make_engine ~seed:0x0123456789ABCDEFL () in
let x = Cromulent.next rng in          (* 64-bit output *)
let d = Cromulent.next_double rng in   (* [0, 1) *)
let r = Cromulent.bounded rng 6L in    (* unbiased [0, 6) *)
```

## Test

Uses only the standard library:

```bash
make test
```
