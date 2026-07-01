package com.cromulent;

import java.util.random.RandomGenerator;

/**
 * The heavier "strong" Cromulent variant. Mirrors {@code cromulent_strong_init}
 * / {@code cromulent_strong_next} and implements {@link RandomGenerator}.
 */
public final class StrongEngine implements RandomGenerator {

    private static final long C1 = 0x9e3779b97f4a7c15L;
    private static final long C2 = 0xbf58476d1ce4e5b9L;

    /** Default seed, shared with the C library. */
    public static final long DEFAULT_SEED = 0x853c49e6748fea9bL;

    private long a;
    private long b;

    public StrongEngine() {
        this(DEFAULT_SEED);
    }

    public StrongEngine(long seed) {
        long[] st = Seeding.expand(seed);
        this.a = st[0];
        this.b = st[1];
    }

    @Override
    public long nextLong() {
        long a = this.a;
        long b = this.b;

        b += Long.rotateLeft(a, 13);
        a = Long.rotateLeft(a, 29) * C1 + b;

        b = Long.rotateLeft(b, 17) ^ a;
        a += Long.rotateLeft(b * C2, 31);

        b += Long.rotateLeft(a, 23);
        a = Long.rotateLeft(a ^ b, 52);

        final long output = a + Long.rotateLeft(b, 41);

        this.a = a + C1;
        this.b = b ^ (a >>> 17);

        return Seeding.mixFast(output);
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
        if (!(o instanceof StrongEngine other)) {
            return false;
        }
        return a == other.a && b == other.b;
    }

    @Override
    public int hashCode() {
        return Long.hashCode(a) * 31 + Long.hashCode(b);
    }
}
