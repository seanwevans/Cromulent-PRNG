// The Cromulent PRNG — a Swift port of the scalar reference generator.
//
// `Engine` reproduces the identical 64-bit stream as the C reference
// implementation (cromulent_init / cromulent_next) for any given seed;
// `StrongEngine` mirrors the heavier cromulent_strong variant. Swift's UInt64
// is a native unsigned type; the wrapping operators (&+, &-, &*) reproduce the
// mod-2^64 arithmetic of the C generator.

private let C1: UInt64 = 0x9e37_79b9_7f4a_7c15
private let C2: UInt64 = 0xbf58_476d_1ce4_e5b9
private let C3: UInt64 = 0x94d0_49bb_1331_11eb
private let C6: UInt64 = 0xd134_2543_de82_ef95
private let MH3: UInt64 = 0xd6e8_feb8_6659_fd93

/// Default seed, shared with the C library.
public let defaultSeed: UInt64 = 0x853c_49e6_748f_ea9b

@inline(__always)
private func rotl(_ x: UInt64, _ k: Int) -> UInt64 {
    return (x << k) | (x >> (64 - k))
}

@inline(__always)
private func mixFast(_ x0: UInt64) -> UInt64 {
    var x = x0
    x ^= x >> 32
    x = x &* MH3
    x ^= x >> 32
    return x
}

/// SplitMix64-style seed expansion, matching cromulent_init.
private func seedExpand(_ seed: UInt64) -> (UInt64, UInt64) {
    var z = seed
    var out = [UInt64](repeating: 0, count: 2)
    for i in 0..<2 {
        z = z &+ C1
        z = (z ^ (z >> 30)) &* C2
        z = (z ^ (z >> 27)) &* C3
        out[i] = z ^ (z >> 31)
    }
    return (out[0], out[1])
}

/// The primary Cromulent engine.
public struct Engine {
    public private(set) var s0: UInt64
    public private(set) var s1: UInt64

    public init(seed: UInt64 = defaultSeed) {
        (s0, s1) = seedExpand(seed)
    }

    /// Advance the state and return the next 64-bit output.
    public mutating func next() -> UInt64 {
        let a = s0
        let b = s1

        s0 = a &* C6 &+ b
        s1 = rotl(b, 31) &+ mixFast(a)

        var r = a &+ rotl(b, 11)
        r ^= r >> 27
        r = r &* C3
        r ^= r >> 27
        return r
    }

    /// Uniform Double in [0, 1) using the top 53 bits.
    public mutating func nextDouble() -> Double {
        return Double(next() >> 11) * (1.0 / 9_007_199_254_740_992.0)
    }

    /// Unbiased uniform integer in [0, n) via Lemire's method. Returns 0 when n == 0.
    public mutating func bounded(_ n: UInt64) -> UInt64 {
        if n == 0 { return 0 }
        var (hi, low) = next().multipliedFullWidth(by: n)
        if low < n {
            let threshold = (0 &- n) % n
            while low < threshold {
                (hi, low) = next().multipliedFullWidth(by: n)
            }
        }
        return hi
    }

    /// Advance the stream by z steps, discarding the output.
    public mutating func discard(_ z: UInt64) {
        var i: UInt64 = 0
        while i < z {
            _ = next()
            i &+= 1
        }
    }
}

/// The heavier "strong" Cromulent variant.
public struct StrongEngine {
    public private(set) var a: UInt64
    public private(set) var b: UInt64

    public init(seed: UInt64 = defaultSeed) {
        (a, b) = seedExpand(seed)
    }

    public mutating func next() -> UInt64 {
        var x = a
        var y = b

        y = y &+ rotl(x, 13)
        x = rotl(x, 29) &* C1 &+ y

        y = rotl(y, 17) ^ x
        x = x &+ rotl(y &* C2, 31)

        y = y &+ rotl(x, 23)
        x = rotl(x ^ y, 52)

        let output = x &+ rotl(y, 41)

        a = x &+ C1
        b = y ^ (x >> 17)

        return mixFast(output)
    }

    public mutating func discard(_ z: UInt64) {
        var i: UInt64 = 0
        while i < z {
            _ = next()
            i &+= 1
        }
    }
}
