//! The Cromulent PRNG — a Rust port of the scalar reference generator.
//!
//! The [`Engine`] produces the identical 64-bit stream as the C reference
//! implementation (`cromulent_init` / `cromulent_next`) for any given seed.
//! [`StrongEngine`] mirrors the heavier `cromulent_strong` variant.
//!
//! The crate is `no_std`-compatible and dependency-free. All arithmetic uses
//! explicit wrapping semantics to match the C generator exactly.

#![no_std]
#![forbid(unsafe_code)]

const C1: u64 = 0x9e37_79b9_7f4a_7c15;
const C2: u64 = 0xbf58_476d_1ce4_e5b9;
const C3: u64 = 0x94d0_49bb_1331_11eb;
const C6: u64 = 0xd134_2543_de82_ef95;
const MH3: u64 = 0xd6e8_feb8_6659_fd93;

/// Default seed, shared with the C library.
pub const DEFAULT_SEED: u64 = 0x853c_49e6_748f_ea9b;

#[inline]
fn mix_fast(mut x: u64) -> u64 {
    x ^= x >> 32;
    x = x.wrapping_mul(MH3);
    x ^= x >> 32;
    x
}

/// SplitMix64-style seed expansion, matching `cromulent_init`.
#[inline]
fn seed_step(z: &mut u64) -> u64 {
    *z = z.wrapping_add(C1);
    *z = (*z ^ (*z >> 30)).wrapping_mul(C2);
    *z = (*z ^ (*z >> 27)).wrapping_mul(C3);
    *z ^ (*z >> 31)
}

/// The primary Cromulent engine.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Engine {
    s0: u64,
    s1: u64,
}

impl Engine {
    /// Create an engine seeded from a single 64-bit value.
    #[inline]
    pub fn new(seed: u64) -> Self {
        let mut z = seed;
        let s0 = seed_step(&mut z);
        let s1 = seed_step(&mut z);
        Self { s0, s1 }
    }

    /// Advance the state and return the next 64-bit output.
    #[inline]
    pub fn next_u64(&mut self) -> u64 {
        let s0 = self.s0;
        let s1 = self.s1;

        self.s0 = s0.wrapping_mul(C6).wrapping_add(s1);
        self.s1 = s1.rotate_left(31).wrapping_add(mix_fast(s0));

        let mut result = s0.wrapping_add(s1.rotate_left(11));
        result ^= result >> 27;
        result = result.wrapping_mul(C3);
        result ^= result >> 27;
        result
    }

    /// Uniform `f64` in `[0, 1)` using the top 53 bits.
    #[inline]
    pub fn next_f64(&mut self) -> f64 {
        (self.next_u64() >> 11) as f64 * (1.0 / (1u64 << 53) as f64)
    }

    /// Uniform `f32` in `[0, 1)` using the top 24 bits.
    #[inline]
    pub fn next_f32(&mut self) -> f32 {
        (self.next_u64() >> 40) as f32 * (1.0 / (1u32 << 24) as f32)
    }

    /// Unbiased uniform integer in `[0, n)` via Lemire's method.
    /// Returns 0 when `n == 0`.
    #[inline]
    pub fn bounded(&mut self, n: u64) -> u64 {
        if n == 0 {
            return 0;
        }
        let mut m = self.next_u64() as u128 * n as u128;
        let mut low = m as u64;
        if low < n {
            let threshold = n.wrapping_neg() % n;
            while low < threshold {
                m = self.next_u64() as u128 * n as u128;
                low = m as u64;
            }
        }
        (m >> 64) as u64
    }

    /// Advance the stream by `z` steps, discarding the output.
    #[inline]
    pub fn discard(&mut self, z: u64) {
        for _ in 0..z {
            self.next_u64();
        }
    }
}

impl Default for Engine {
    fn default() -> Self {
        Self::new(DEFAULT_SEED)
    }
}

impl Iterator for Engine {
    type Item = u64;
    #[inline]
    fn next(&mut self) -> Option<u64> {
        Some(self.next_u64())
    }
}

/// The "strong" Cromulent variant.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct StrongEngine {
    a: u64,
    b: u64,
}

impl StrongEngine {
    #[inline]
    pub fn new(seed: u64) -> Self {
        let mut z = seed;
        let a = seed_step(&mut z);
        let b = seed_step(&mut z);
        Self { a, b }
    }

    #[inline]
    pub fn next_u64(&mut self) -> u64 {
        let mut a = self.a;
        let mut b = self.b;

        b = b.wrapping_add(a.rotate_left(13));
        a = a.rotate_left(29).wrapping_mul(C1).wrapping_add(b);

        b = b.rotate_left(17) ^ a;
        a = a.wrapping_add(b.wrapping_mul(C2).rotate_left(31));

        b = b.wrapping_add(a.rotate_left(23));
        a = (a ^ b).rotate_left(52);

        let output = a.wrapping_add(b.rotate_left(41));

        self.a = a.wrapping_add(C1);
        self.b = b ^ (a >> 17);

        mix_fast(output)
    }

    #[inline]
    pub fn discard(&mut self, z: u64) {
        for _ in 0..z {
            self.next_u64();
        }
    }
}

impl Default for StrongEngine {
    fn default() -> Self {
        Self::new(DEFAULT_SEED)
    }
}

impl Iterator for StrongEngine {
    type Item = u64;
    #[inline]
    fn next(&mut self) -> Option<u64> {
        Some(self.next_u64())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const ENGINE_REF: [u64; 8] = [
        0x8b08_4984_8b39_737d,
        0x829e_cfb6_61e3_a84d,
        0x6cfb_2afb_89b5_dc83,
        0x8ad5_c0d4_9066_9f95,
        0x8d44_59e6_318f_2474,
        0xa0b9_07b8_4599_0f61,
        0x2143_675f_2f4f_f1ec,
        0x38ff_f6f9_c33c_4f8f,
    ];

    const STRONG_REF: [u64; 8] = [
        0xa1e9_fb73_cc5c_77fa,
        0xd8bc_61a9_6acc_c72e,
        0x3f98_dad0_bcb1_c8f3,
        0xb179_513c_44fe_1f0a,
        0x413b_884b_e5b9_955f,
        0x4b68_2d94_9162_39a1,
        0xe7b9_3a46_00d7_7791,
        0x6a54_f95b_111a_3555,
    ];

    #[test]
    fn matches_reference() {
        let mut e = Engine::new(0x0123_4567_89AB_CDEF);
        for &want in &ENGINE_REF {
            assert_eq!(e.next_u64(), want);
        }
    }

    #[test]
    fn strong_matches_reference() {
        let mut e = StrongEngine::new(0x0123_4567_89AB_CDEF);
        for &want in &STRONG_REF {
            assert_eq!(e.next_u64(), want);
        }
    }

    #[test]
    fn double_in_range() {
        let mut e = Engine::new(42);
        assert!((e.next_f64() - 0.429_906_490_881_153_07).abs() < 1e-15);
        for _ in 0..10_000 {
            let d = e.next_f64();
            assert!((0.0..1.0).contains(&d));
        }
    }

    #[test]
    fn bounded_range() {
        let mut e = Engine::new(99);
        assert_eq!(e.bounded(0), 0);
        for _ in 0..10_000 {
            assert!(e.bounded(7) < 7);
        }
    }

    #[test]
    fn discard_equivalence() {
        let mut a = Engine::new(555);
        let mut b = Engine::new(555);
        a.discard(50);
        for _ in 0..50 {
            b.next_u64();
        }
        assert_eq!(a, b);
    }
}
