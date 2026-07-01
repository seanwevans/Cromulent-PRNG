package com.cromulent;

import java.util.random.RandomGenerator;

/**
 * The Cromulent PRNG — a Java port of the scalar reference generator.
 *
 * <p>This engine produces the identical 64-bit stream as the C reference
 * implementation ({@code cromulent_init} / {@code cromulent_next}) for any given
 * seed. It implements {@link RandomGenerator}, so the standard helpers
 * ({@code nextInt(bound)}, {@code nextDouble()}, {@code ints()}/{@code longs()}
 * streams, etc.) are available for free. Notably {@code RandomGenerator}'s
 * default {@code nextDouble()} is {@code (nextLong() >>> 11) * 0x1.0p-53}, which
 * matches {@code cromulent_double} exactly.
 *
 * <p>Java's {@code long} is 64-bit two's complement; addition, multiplication,
 * and bitwise operations wrap identically to the unsigned C generator, so the
 * only care needed is to use unsigned shifts ({@code >>>}) and unsigned
 * comparisons where the value is interpreted as unsigned.
 */
public final class CromulentEngine implements RandomGenerator {

    private static final long C1 = 0x9e3779b97f4a7c15L;
    private static final long C3 = 0x94d049bb133111ebL;
    private static final long C6 = 0xd1342543de82ef95L;
    private static final long MH3 = 0xd6e8feb86659fd93L;

    /** Default seed, shared with the C library. */
    public static final long DEFAULT_SEED = 0x853c49e6748fea9bL;

    private long s0;
    private long s1;

    /** Creates an engine seeded with {@link #DEFAULT_SEED}. */
    public CromulentEngine() {
        this(DEFAULT_SEED);
    }

    /** Creates an engine seeded from a single 64-bit value. */
    public CromulentEngine(long seed) {
        long[] st = Seeding.expand(seed);
        this.s0 = st[0];
        this.s1 = st[1];
    }

    /** Advances the state and returns the next 64-bit output. */
    @Override
    public long nextLong() {
        final long s0 = this.s0;
        final long s1 = this.s1;

        this.s0 = s0 * C6 + s1;
        this.s1 = Long.rotateLeft(s1, 31) + Seeding.mixFast(s0);

        long result = s0 + Long.rotateLeft(s1, 11);
        result ^= result >>> 27;
        result *= C3;
        result ^= result >>> 27;
        return result;
    }

    /**
     * Unbiased uniform integer in {@code [0, n)} via Lemire's method, treating
     * {@code n} as unsigned. Returns 0 when {@code n == 0}.
     */
    public long bounded(long n) {
        if (n == 0) {
            return 0;
        }
        long x = nextLong();
        long low = x * n;
        long hi = Seeding.unsignedMultiplyHigh(x, n);
        if (Long.compareUnsigned(low, n) < 0) {
            long threshold = Long.remainderUnsigned(-n, n);
            while (Long.compareUnsigned(low, threshold) < 0) {
                x = nextLong();
                low = x * n;
                hi = Seeding.unsignedMultiplyHigh(x, n);
            }
        }
        return hi;
    }

    /** Advances the stream by {@code z} steps, discarding the output. */
    public void discard(long z) {
        for (long i = 0; i < z; i++) {
            nextLong();
        }
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (!(o instanceof CromulentEngine other)) {
            return false;
        }
        return s0 == other.s0 && s1 == other.s1;
    }

    @Override
    public int hashCode() {
        return Long.hashCode(s0) * 31 + Long.hashCode(s1);
    }
}
