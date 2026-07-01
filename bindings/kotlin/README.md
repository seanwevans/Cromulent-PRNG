# Cromulent PRNG — Kotlin

A dependency-free Kotlin port of the scalar Cromulent generator.
`CromulentEngine` reproduces the C reference stream (`cromulent_init` /
`cromulent_next`) bit-for-bit; `StrongEngine` mirrors the heavier
`cromulent_strong` variant. It uses `Long` with unsigned right shift (`ushr`)
and `java.lang.Long` helpers for rotation and unsigned comparisons, so it
builds on any Kotlin/JVM version.

```kotlin
import com.cromulent.CromulentEngine

val rng = CromulentEngine(0x0123456789ABCDEFL)
val x = rng.nextLong()
val d = rng.nextDouble()   // [0, 1)
val r = rng.bounded(6)     // unbiased [0, 6), unsigned
```

## Test

No build tool required — compile the sources and run:

```bash
kotlinc src/Cromulent.kt src/Test.kt -include-runtime -d cromulent.jar
java -jar cromulent.jar
```
