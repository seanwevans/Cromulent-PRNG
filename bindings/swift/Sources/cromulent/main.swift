// Self-contained test runner for the Swift Cromulent port. Verifies bit-for-bit
// parity with the C reference vectors and basic range/discard behavior. Exits
// non-zero on failure.

#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

let engineRef: [UInt64] = [
    0x8b0849848b39737d, 0x829ecfb661e3a84d, 0x6cfb2afb89b5dc83,
    0x8ad5c0d490669f95, 0x8d4459e6318f2474, 0xa0b907b845990f61,
    0x2143675f2f4ff1ec, 0x38fff6f9c33c4f8f,
]

let strongRef: [UInt64] = [
    0xa1e9fb73cc5c77fa, 0xd8bc61a96accc72e, 0x3f98dad0bcb1c8f3,
    0xb179513c44fe1f0a, 0x413b884be5b9955f, 0x4b682d94916239a1,
    0xe7b93a4600d77791, 0x6a54f95b111a3555,
]

var failures = 0
func check(_ cond: Bool, _ msg: String) {
    if !cond {
        fputs("FAIL: \(msg)\n", stderr)
        failures += 1
    }
}

print("Running Cromulent Swift engine tests")

print("Testing engine matches C reference... ", terminator: "")
var e = Engine(seed: 0x0123456789ABCDEF)
for (i, want) in engineRef.enumerated() {
    check(e.next() == want, "engine output \(i)")
}
print("OK")

print("Testing strong engine matches C reference... ", terminator: "")
var s = StrongEngine(seed: 0x0123456789ABCDEF)
for (i, want) in strongRef.enumerated() {
    check(s.next() == want, "strong output \(i)")
}
print("OK")

print("Testing nextDouble range... ", terminator: "")
var d = Engine(seed: 42)
check(abs(d.nextDouble() - 0.42990649088115307) < 1e-15, "first double")
for _ in 0..<10000 {
    let v = d.nextDouble()
    check(v >= 0.0 && v < 1.0, "double in range")
}
print("OK")

print("Testing bounded range... ", terminator: "")
var b = Engine(seed: 99)
check(b.bounded(0) == 0, "bounded(0)")
for _ in 0..<10000 {
    check(b.bounded(7) < 7, "bounded(7) < 7")
}
print("OK")

print("Testing discard equivalence... ", terminator: "")
var a1 = Engine(seed: 555)
var a2 = Engine(seed: 555)
a1.discard(50)
for _ in 0..<50 { _ = a2.next() }
check(a1.s0 == a2.s0 && a1.s1 == a2.s1, "discard(n) == n calls")
print("OK")

if failures == 0 {
    print("All Swift engine tests passed successfully!")
    exit(0)
} else {
    print("\(failures) check(s) failed!")
    exit(1)
}
