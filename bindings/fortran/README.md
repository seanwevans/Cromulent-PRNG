# Cromulent PRNG — Fortran

A modern Fortran (F2008) port of the scalar Cromulent generator. `cromulent_engine`
and `strong_engine` are derived types with type-bound procedures that reproduce
the C reference stream (`cromulent_init` / `cromulent_next`) bit-for-bit.

```fortran
use cromulent
type(cromulent_engine) :: rng
integer(int64) :: x, r
real(real64) :: d

rng = make_engine(int(z'0123456789ABCDEF', int64))
x = rng%next()          ! 64-bit output
d = rng%next_double()   ! [0, 1)
r = rng%bounded(6_int64) ! unbiased [0, 6), unsigned
```

Fortran integers are signed; the port relies on two's-complement wraparound for
`+`/`*` and the bit intrinsics, so **compile with `-fno-range-check`** (the
Makefile does this) to accept the 64-bit hex constants whose high bit is set.

## Test

```bash
make test
```
