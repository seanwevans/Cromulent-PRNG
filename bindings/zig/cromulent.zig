//! The Cromulent PRNG -- a Zig port of the scalar reference generator.
//!
//! `Engine` reproduces the identical 64-bit stream as the C reference
//! implementation (cromulent_init / cromulent_next) for any given seed;
//! `StrongEngine` mirrors the heavier cromulent_strong variant. Zig's `u64` is
//! a native unsigned type; the wrapping operators (`+%`, `*%`, `-%`) reproduce
//! the mod-2^64 arithmetic of the C generator.

const std = @import("std");

const C1: u64 = 0x9e3779b97f4a7c15;
const C2: u64 = 0xbf58476d1ce4e5b9;
const C3: u64 = 0x94d049bb133111eb;
const C6: u64 = 0xd1342543de82ef95;
const MH3: u64 = 0xd6e8feb86659fd93;

/// Default seed, shared with the C library.
pub const default_seed: u64 = 0x853c49e6748fea9b;

fn mixFast(x0: u64) u64 {
    var x = x0;
    x ^= x >> 32;
    x *%= MH3;
    x ^= x >> 32;
    return x;
}

/// SplitMix64-style seed expansion, matching cromulent_init.
fn seedExpand(seed: u64) [2]u64 {
    var z = seed;
    var out: [2]u64 = undefined;
    var i: usize = 0;
    while (i < 2) : (i += 1) {
        z +%= C1;
        z = (z ^ (z >> 30)) *% C2;
        z = (z ^ (z >> 27)) *% C3;
        out[i] = z ^ (z >> 31);
    }
    return out;
}

/// The primary Cromulent engine.
pub const Engine = struct {
    s0: u64,
    s1: u64,

    pub fn init(seed: u64) Engine {
        const st = seedExpand(seed);
        return .{ .s0 = st[0], .s1 = st[1] };
    }

    /// Advance the state and return the next 64-bit output.
    pub fn next(self: *Engine) u64 {
        const s0 = self.s0;
        const s1 = self.s1;

        self.s0 = s0 *% C6 +% s1;
        self.s1 = std.math.rotl(u64, s1, 31) +% mixFast(s0);

        var r = s0 +% std.math.rotl(u64, s1, 11);
        r ^= r >> 27;
        r *%= C3;
        r ^= r >> 27;
        return r;
    }

    /// Uniform f64 in [0, 1) using the top 53 bits.
    pub fn nextDouble(self: *Engine) f64 {
        return @as(f64, @floatFromInt(self.next() >> 11)) * (1.0 / 9007199254740992.0);
    }

    /// Unbiased uniform integer in [0, n) via Lemire's method. Returns 0 when n == 0.
    pub fn bounded(self: *Engine, n: u64) u64 {
        if (n == 0) return 0;
        var m: u128 = @as(u128, self.next()) * @as(u128, n);
        var low: u64 = @truncate(m);
        if (low < n) {
            const threshold: u64 = (@as(u64, 0) -% n) % n;
            while (low < threshold) {
                m = @as(u128, self.next()) * @as(u128, n);
                low = @truncate(m);
            }
        }
        return @truncate(m >> 64);
    }

    /// Advance the stream by z steps, discarding the output.
    pub fn discard(self: *Engine, z: u64) void {
        var i: u64 = 0;
        while (i < z) : (i += 1) _ = self.next();
    }
};

/// The heavier "strong" Cromulent variant.
pub const StrongEngine = struct {
    a: u64,
    b: u64,

    pub fn init(seed: u64) StrongEngine {
        const st = seedExpand(seed);
        return .{ .a = st[0], .b = st[1] };
    }

    pub fn next(self: *StrongEngine) u64 {
        var a = self.a;
        var b = self.b;

        b +%= std.math.rotl(u64, a, 13);
        a = std.math.rotl(u64, a, 29) *% C1 +% b;

        b = std.math.rotl(u64, b, 17) ^ a;
        a +%= std.math.rotl(u64, b *% C2, 31);

        b +%= std.math.rotl(u64, a, 23);
        a = std.math.rotl(u64, a ^ b, 52);

        const output = a +% std.math.rotl(u64, b, 41);

        self.a = a +% C1;
        self.b = b ^ (a >> 17);

        return mixFast(output);
    }

    pub fn discard(self: *StrongEngine, z: u64) void {
        var i: u64 = 0;
        while (i < z) : (i += 1) _ = self.next();
    }
};

const engine_ref = [_]u64{
    0x8b0849848b39737d, 0x829ecfb661e3a84d, 0x6cfb2afb89b5dc83,
    0x8ad5c0d490669f95, 0x8d4459e6318f2474, 0xa0b907b845990f61,
    0x2143675f2f4ff1ec, 0x38fff6f9c33c4f8f,
};

const strong_ref = [_]u64{
    0xa1e9fb73cc5c77fa, 0xd8bc61a96accc72e, 0x3f98dad0bcb1c8f3,
    0xb179513c44fe1f0a, 0x413b884be5b9955f, 0x4b682d94916239a1,
    0xe7b93a4600d77791, 0x6a54f95b111a3555,
};

test "engine matches C reference" {
    var e = Engine.init(0x0123456789ABCDEF);
    for (engine_ref) |want| {
        try std.testing.expectEqual(want, e.next());
    }
}

test "strong engine matches C reference" {
    var e = StrongEngine.init(0x0123456789ABCDEF);
    for (strong_ref) |want| {
        try std.testing.expectEqual(want, e.next());
    }
}

test "nextDouble in range" {
    var e = Engine.init(42);
    try std.testing.expect(@abs(e.nextDouble() - 0.42990649088115307) < 1e-15);
    var i: usize = 0;
    while (i < 10000) : (i += 1) {
        const v = e.nextDouble();
        try std.testing.expect(v >= 0.0 and v < 1.0);
    }
}

test "bounded in range" {
    var e = Engine.init(99);
    try std.testing.expectEqual(@as(u64, 0), e.bounded(0));
    var i: usize = 0;
    while (i < 10000) : (i += 1) {
        try std.testing.expect(e.bounded(7) < 7);
    }
}

test "discard equivalence" {
    var a = Engine.init(555);
    var b = Engine.init(555);
    a.discard(50);
    var i: usize = 0;
    while (i < 50) : (i += 1) _ = b.next();
    try std.testing.expectEqual(a.s0, b.s0);
    try std.testing.expectEqual(a.s1, b.s1);
}
