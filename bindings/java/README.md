# Cromulent PRNG — Java

A dependency-free Java port of the scalar Cromulent generator.
`CromulentEngine` implements `java.util.random.RandomGenerator`, so the standard
helpers (`nextInt(bound)`, `nextDouble()`, `ints()`/`longs()` streams, …) work
out of the box — and `RandomGenerator`'s default `nextDouble()` is
`(nextLong() >>> 11) * 0x1.0p-53`, matching `cromulent_double` exactly.

`CromulentEngine` reproduces the C reference stream (`cromulent_init` /
`cromulent_next`) bit-for-bit; `StrongEngine` mirrors the heavier
`cromulent_strong` variant.

```java
import com.cromulent.CromulentEngine;

var rng = new CromulentEngine(0x0123456789ABCDEFL);
long x = rng.nextLong();
int roll = rng.nextInt(6);      // [0, 6)
double d = rng.nextDouble();    // [0, 1)
long r = rng.bounded(6);        // unbiased [0, 6), unsigned
```

## Test

No build tool required — compile the sources and run the self-test:

```bash
javac -d out $(find src -name '*.java')
java -cp out com.cromulent.CromulentTest
```
