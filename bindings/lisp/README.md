# Cromulent PRNG — Common Lisp

A dependency-free Common Lisp port of the scalar Cromulent generator.
`make-engine` / `engine-next` reproduce the C reference stream
(`cromulent_init` / `cromulent_next`) bit-for-bit; `make-strong` /
`strong-next` mirror the heavier `cromulent_strong` variant. Common Lisp's
arbitrary-precision integers are masked to 64 bits to reproduce the wrapping
behavior of the C generator.

```lisp
(load "src/cromulent.lisp")
(in-package :cromulent)

(let ((rng (make-engine #x0123456789ABCDEF)))
  (engine-next rng)          ; 64-bit integer
  (engine-next-double rng)   ; [0, 1)
  (engine-bounded rng 6))    ; unbiased [0, 6)
```

## Test

Tested with SBCL (any conforming implementation should work):

```bash
sbcl --script test/test.lisp
```
