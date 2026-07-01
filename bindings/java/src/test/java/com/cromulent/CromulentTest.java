package com.cromulent;

import java.util.random.RandomGenerator;

/**
 * Self-contained test runner (no external test framework) for the Java port.
 * Verifies bit-for-bit parity with the C reference vectors and exercises the
 * RandomGenerator integration. Exits non-zero on the first failure.
 */
public final class CromulentTest {

    private static final long[] ENGINE_REF = {
        0x8b0849848b39737dL, 0x829ecfb661e3a84dL, 0x6cfb2afb89b5dc83L,
        0x8ad5c0d490669f95L, 0x8d4459e6318f2474L, 0xa0b907b845990f61L,
        0x2143675f2f4ff1ecL, 0x38fff6f9c33c4f8fL,
    };

    private static final long[] STRONG_REF = {
        0xa1e9fb73cc5c77faL, 0xd8bc61a96accc72eL, 0x3f98dad0bcb1c8f3L,
        0xb179513c44fe1f0aL, 0x413b884be5b9955fL, 0x4b682d94916239a1L,
        0xe7b93a4600d77791L, 0x6a54f95b111a3555L,
    };

    private static int failures = 0;

    private static void check(boolean cond, String msg) {
        if (!cond) {
            System.err.println("FAIL: " + msg);
            failures++;
        }
    }

    private static void testMatchesReference() {
        System.out.print("Testing engine matches C reference... ");
        CromulentEngine e = new CromulentEngine(0x0123456789ABCDEFL);
        for (int i = 0; i < ENGINE_REF.length; i++) {
            check(e.nextLong() == ENGINE_REF[i], "engine output " + i);
        }
        System.out.println("OK");
    }

    private static void testStrongMatchesReference() {
        System.out.print("Testing strong engine matches C reference... ");
        StrongEngine e = new StrongEngine(0x0123456789ABCDEFL);
        for (int i = 0; i < STRONG_REF.length; i++) {
            check(e.nextLong() == STRONG_REF[i], "strong output " + i);
        }
        System.out.println("OK");
    }

    private static void testRandomGeneratorIntegration() {
        System.out.print("Testing RandomGenerator integration... ");
        RandomGenerator rng = new CromulentEngine(12345);

        // Default nextDouble() is (nextLong() >>> 11) * 0x1.0p-53, matching C.
        RandomGenerator d = new CromulentEngine(42);
        check(Math.abs(d.nextDouble() - 0.42990649088115307) < 1e-15,
              "nextDouble matches cromulent_double");

        for (int i = 0; i < 10000; i++) {
            int roll = rng.nextInt(6);
            check(roll >= 0 && roll < 6, "nextInt(6) in range");
            double v = rng.nextDouble();
            check(v >= 0.0 && v < 1.0, "nextDouble in [0,1)");
        }
        System.out.println("OK");
    }

    private static void testBounded() {
        System.out.print("Testing bounded()... ");
        CromulentEngine e = new CromulentEngine(99);
        check(e.bounded(0) == 0, "bounded(0) == 0");
        for (int i = 0; i < 10000; i++) {
            check(Long.compareUnsigned(e.bounded(7), 7) < 0, "bounded(7) < 7");
        }
        System.out.println("OK");
    }

    private static void testDiscardAndEquals() {
        System.out.print("Testing discard/equals... ");
        CromulentEngine a = new CromulentEngine(555);
        CromulentEngine b = new CromulentEngine(555);
        a.discard(50);
        for (int i = 0; i < 50; i++) {
            b.nextLong();
        }
        check(a.equals(b), "discard(n) equals n calls");
        System.out.println("OK");
    }

    public static void main(String[] args) {
        System.out.println("Running Cromulent Java engine tests");
        testMatchesReference();
        testStrongMatchesReference();
        testRandomGeneratorIntegration();
        testBounded();
        testDiscardAndEquals();

        if (failures == 0) {
            System.out.println("All Java engine tests passed successfully!");
        } else {
            System.out.println(failures + " check(s) failed!");
            System.exit(1);
        }
    }
}
