# Cromulent PRNG — Racket

A Racket port of the scalar Cromulent generator. `make-engine` /
`engine-next!` reproduce the C reference stream (`cromulent_init` /
`cromulent_next`) bit-for-bit; `make-strong-engine` / `strong-engine-next!`
mirror the heavier `cromulent_strong` variant.

```racket
(require "cromulent.rkt")

(define rng (make-engine #x0123456789ABCDEF))
(engine-next! rng)          ; 64-bit integer
(engine-next-double! rng)   ; [0, 1)
(engine-bounded! rng 6)     ; unbiased [0, 6)
```

## Test

```bash
raco test cromulent.rkt
```
