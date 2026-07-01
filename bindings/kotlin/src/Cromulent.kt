package com.cromulent

/**
 * The Cromulent PRNG — a Kotlin port of the scalar reference generator.
 *
 * `CromulentEngine` reproduces the identical 64-bit stream as the C reference
 * implementation (`cromulent_init` / `cromulent_next`) for any given seed;
 * `StrongEngine` mirrors the heavier `cromulent_strong` variant.
 *
 * Kotlin's `Long` is 64-bit two's complement; `+`, `*`, and the bitwise
 * operators wrap identically to the unsigned C generator, so the only care
 * needed is to use the unsigned right shift (`ushr`) and unsigned comparisons
 * where a value is interpreted as unsigned.
 */
internal object Const {
    val C1: Long = java.lang.Long.parseUnsignedLong("9e3779b97f4a7c15", 16)
    val C2: Long = java.lang.Long.parseUnsignedLong("bf58476d1ce4e5b9", 16)
    val C3: Long = java.lang.Long.parseUnsignedLong("94d049bb133111eb", 16)
    val C6: Long = java.lang.Long.parseUnsignedLong("d1342543de82ef95", 16)
    val MH3: Long = java.lang.Long.parseUnsignedLong("d6e8feb86659fd93", 16)

    /** Default seed, shared with the C library. */
    val DEFAULT_SEED: Long = java.lang.Long.parseUnsignedLong("853c49e6748fea9b", 16)

    fun mixFast(x0: Long): Long {
        var x = x0
        x = x xor (x ushr 32)
        x *= MH3
        x = x xor (x ushr 32)
        return x
    }

    /** SplitMix64-style seed expansion, matching cromulent_init. */
    fun seedExpand(seed: Long): LongArray {
        var z = seed
        val out = LongArray(2)
        for (i in 0 until 2) {
            z += C1
            z = (z xor (z ushr 30)) * C2
            z = (z xor (z ushr 27)) * C3
            out[i] = z xor (z ushr 31)
        }
        return out
    }

    /** High 64 bits of the unsigned 128-bit product a*b (32-bit limbs). */
    fun umulHigh(a: Long, b: Long): Long {
        val aLo = a and 0xffffffffL
        val aHi = a ushr 32
        val bLo = b and 0xffffffffL
        val bHi = b ushr 32
        val lolo = aLo * bLo
        val hilo = aHi * bLo
        val lohi = aLo * bHi
        val hihi = aHi * bHi
        val carry = ((lolo ushr 32) + (hilo and 0xffffffffL) + (lohi and 0xffffffffL)) ushr 32
        return hihi + (hilo ushr 32) + (lohi ushr 32) + carry
    }
}

/** The primary Cromulent engine. */
class CromulentEngine(seed: Long = Const.DEFAULT_SEED) {
    private var s0: Long
    private var s1: Long

    init {
        val st = Const.seedExpand(seed)
        s0 = st[0]
        s1 = st[1]
    }

    /** Advance the state and return the next 64-bit output. */
    fun nextLong(): Long {
        val a = s0
        val b = s1
        s0 = a * Const.C6 + b
        s1 = java.lang.Long.rotateLeft(b, 31) + Const.mixFast(a)
        var result = a + java.lang.Long.rotateLeft(b, 11)
        result = result xor (result ushr 27)
        result *= Const.C3
        result = result xor (result ushr 27)
        return result
    }

    /** Uniform double in [0, 1) using the top 53 bits. */
    fun nextDouble(): Double = (nextLong() ushr 11).toDouble() * (1.0 / (1L shl 53))

    /** Unbiased uniform integer in [0, n) via Lemire's method (n unsigned). */
    fun bounded(n: Long): Long {
        if (n == 0L) return 0L
        var x = nextLong()
        var low = x * n
        var hi = Const.umulHigh(x, n)
        if (java.lang.Long.compareUnsigned(low, n) < 0) {
            val threshold = java.lang.Long.remainderUnsigned(-n, n)
            while (java.lang.Long.compareUnsigned(low, threshold) < 0) {
                x = nextLong()
                low = x * n
                hi = Const.umulHigh(x, n)
            }
        }
        return hi
    }

    /** Advance the stream by z steps, discarding the output. */
    fun discard(z: Long) {
        var i = 0L
        while (i < z) {
            nextLong()
            i++
        }
    }

    fun state(): Pair<Long, Long> = Pair(s0, s1)
}

/** The heavier "strong" Cromulent variant. */
class StrongEngine(seed: Long = Const.DEFAULT_SEED) {
    private var a: Long
    private var b: Long

    init {
        val st = Const.seedExpand(seed)
        a = st[0]
        b = st[1]
    }

    fun nextLong(): Long {
        var x = a
        var y = b
        y += java.lang.Long.rotateLeft(x, 13)
        x = java.lang.Long.rotateLeft(x, 29) * Const.C1 + y
        y = java.lang.Long.rotateLeft(y, 17) xor x
        x += java.lang.Long.rotateLeft(y * Const.C2, 31)
        y += java.lang.Long.rotateLeft(x, 23)
        x = java.lang.Long.rotateLeft(x xor y, 52)
        val output = x + java.lang.Long.rotateLeft(y, 41)
        a = x + Const.C1
        b = y xor (x ushr 17)
        return Const.mixFast(output)
    }

    fun discard(z: Long) {
        var i = 0L
        while (i < z) {
            nextLong()
            i++
        }
    }

    fun state(): Pair<Long, Long> = Pair(a, b)
}
