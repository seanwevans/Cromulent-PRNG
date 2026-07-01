package com.cromulent

private val ENGINE_REF = longArrayOf(
    java.lang.Long.parseUnsignedLong("8b0849848b39737d", 16),
    java.lang.Long.parseUnsignedLong("829ecfb661e3a84d", 16),
    java.lang.Long.parseUnsignedLong("6cfb2afb89b5dc83", 16),
    java.lang.Long.parseUnsignedLong("8ad5c0d490669f95", 16),
    java.lang.Long.parseUnsignedLong("8d4459e6318f2474", 16),
    java.lang.Long.parseUnsignedLong("a0b907b845990f61", 16),
    java.lang.Long.parseUnsignedLong("2143675f2f4ff1ec", 16),
    java.lang.Long.parseUnsignedLong("38fff6f9c33c4f8f", 16)
)

private val STRONG_REF = longArrayOf(
    java.lang.Long.parseUnsignedLong("a1e9fb73cc5c77fa", 16),
    java.lang.Long.parseUnsignedLong("d8bc61a96accc72e", 16),
    java.lang.Long.parseUnsignedLong("3f98dad0bcb1c8f3", 16),
    java.lang.Long.parseUnsignedLong("b179513c44fe1f0a", 16),
    java.lang.Long.parseUnsignedLong("413b884be5b9955f", 16),
    java.lang.Long.parseUnsignedLong("4b682d94916239a1", 16),
    java.lang.Long.parseUnsignedLong("e7b93a4600d77791", 16),
    java.lang.Long.parseUnsignedLong("6a54f95b111a3555", 16)
)

private var failures = 0

private fun check(cond: Boolean, msg: String) {
    if (!cond) {
        System.err.println("FAIL: $msg")
        failures++
    }
}

fun main() {
    println("Running Cromulent Kotlin engine tests")

    print("Testing engine matches C reference... ")
    val e = CromulentEngine(java.lang.Long.parseUnsignedLong("0123456789ABCDEF", 16))
    for (i in ENGINE_REF.indices) check(e.nextLong() == ENGINE_REF[i], "engine output $i")
    println("OK")

    print("Testing strong engine matches C reference... ")
    val s = StrongEngine(java.lang.Long.parseUnsignedLong("0123456789ABCDEF", 16))
    for (i in STRONG_REF.indices) check(s.nextLong() == STRONG_REF[i], "strong output $i")
    println("OK")

    print("Testing nextDouble range... ")
    val d = CromulentEngine(42)
    check(Math.abs(d.nextDouble() - 0.42990649088115307) < 1e-15, "first double")
    for (i in 0 until 10000) {
        val v = d.nextDouble()
        check(v >= 0.0 && v < 1.0, "double in range")
    }
    println("OK")

    print("Testing bounded... ")
    val b = CromulentEngine(99)
    check(b.bounded(0) == 0L, "bounded(0)")
    for (i in 0 until 10000) {
        check(java.lang.Long.compareUnsigned(b.bounded(7), 7) < 0, "bounded(7) < 7")
    }
    println("OK")

    print("Testing discard equivalence... ")
    val a1 = CromulentEngine(555)
    val a2 = CromulentEngine(555)
    a1.discard(50)
    for (i in 0 until 50) a2.nextLong()
    check(a1.state() == a2.state(), "discard(n) == n calls")
    println("OK")

    if (failures == 0) {
        println("All Kotlin engine tests passed successfully!")
    } else {
        println("$failures check(s) failed!")
        System.exit(1)
    }
}
