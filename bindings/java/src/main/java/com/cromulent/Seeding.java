package com.cromulent;

/** Shared helpers for the Cromulent engines. */
final class Seeding {

    private static final long C1 = 0x9e3779b97f4a7c15L;
    private static final long C2 = 0xbf58476d1ce4e5b9L;
    private static final long C3 = 0x94d049bb133111ebL;
    private static final long MH3 = 0xd6e8feb86659fd93L;

    private Seeding() {
    }

    static long mixFast(long x) {
        x ^= x >>> 32;
        x *= MH3;
        x ^= x >>> 32;
        return x;
    }

    /** SplitMix64-style seed expansion, matching {@code cromulent_init}. */
    static long[] expand(long seed) {
        long z = seed;
        long[] out = new long[2];
        for (int i = 0; i < 2; i++) {
            z += C1;
            z = (z ^ (z >>> 30)) * C2;
            z = (z ^ (z >>> 27)) * C3;
            out[i] = z ^ (z >>> 31);
        }
        return out;
    }

    /**
     * High 64 bits of the unsigned 128-bit product {@code a * b}. Implemented
     * with 32-bit limbs so it works on any JDK (independent of
     * {@code Math.unsignedMultiplyHigh}, which is JDK 18+).
     */
    static long unsignedMultiplyHigh(long a, long b) {
        long aLo = a & 0xffffffffL;
        long aHi = a >>> 32;
        long bLo = b & 0xffffffffL;
        long bHi = b >>> 32;

        long lolo = aLo * bLo;
        long hilo = aHi * bLo;
        long lohi = aLo * bHi;
        long hihi = aHi * bHi;

        long carry = ((lolo >>> 32) + (hilo & 0xffffffffL) + (lohi & 0xffffffffL)) >>> 32;
        return hihi + (hilo >>> 32) + (lohi >>> 32) + carry;
    }
}
