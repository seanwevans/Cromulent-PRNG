// The Cromulent PRNG — a JavaScript port of the scalar reference generator.
//
// `Engine` produces the identical 64-bit stream as the C reference
// implementation (cromulent_init / cromulent_next) for any given seed.
// `StrongEngine` mirrors the heavier cromulent_strong variant.
//
// JavaScript numbers cannot represent 64-bit integers exactly, so the state and
// all arithmetic use BigInt, masked back to 64 bits with `MASK` to reproduce
// the wrapping behavior of the C generator.

const MASK = (1n << 64n) - 1n;

const C1 = 0x9e3779b97f4a7c15n;
const C2 = 0xbf58476d1ce4e5b9n;
const C3 = 0x94d049bb133111ebn;
const C6 = 0xd1342543de82ef95n;
const MH3 = 0xd6e8feb86659fd93n;

/** Default seed, shared with the C library. */
export const DEFAULT_SEED = 0x853c49e6748fea9bn;

function rotl(x, k) {
  return ((x << k) | (x >> (64n - k))) & MASK;
}

function mixFast(x) {
  x ^= x >> 32n;
  x = (x * MH3) & MASK;
  x ^= x >> 32n;
  return x;
}

// SplitMix64-style seed expansion, matching cromulent_init.
function seedExpand(seed) {
  let z = BigInt.asUintN(64, seed);
  const out = [];
  for (let i = 0; i < 2; i++) {
    z = (z + C1) & MASK;
    z = ((z ^ (z >> 30n)) * C2) & MASK;
    z = ((z ^ (z >> 27n)) * C3) & MASK;
    out.push(z ^ (z >> 31n));
  }
  return out;
}

/** The primary Cromulent generator. */
export class Engine {
  #s0;
  #s1;

  constructor(seed = DEFAULT_SEED) {
    [this.#s0, this.#s1] = seedExpand(BigInt(seed));
  }

  /** Advance the state and return the next 64-bit output as a BigInt. */
  nextU64() {
    const s0 = this.#s0;
    const s1 = this.#s1;

    this.#s0 = (s0 * C6 + s1) & MASK;
    this.#s1 = (rotl(s1, 31n) + mixFast(s0)) & MASK;

    let result = (s0 + rotl(s1, 11n)) & MASK;
    result ^= result >> 27n;
    result = (result * C3) & MASK;
    result ^= result >> 27n;
    return result;
  }

  /** Uniform Number in [0, 1) using the top 53 bits. */
  nextDouble() {
    return Number(this.nextU64() >> 11n) * 2 ** -53;
  }

  /** Uniform Number in [0, 1) using the top 24 bits (single precision). */
  nextFloat() {
    return Number(this.nextU64() >> 40n) * 2 ** -24;
  }

  /**
   * Unbiased uniform integer in [0, n) via Lemire's method.
   * Returns 0n when n is 0n.
   * @param {bigint} n
   */
  bounded(n) {
    n = BigInt(n);
    if (n === 0n) return 0n;
    let m = this.nextU64() * n;
    let low = m & MASK;
    if (low < n) {
      const threshold = ((MASK + 1n - n) % n);
      while (low < threshold) {
        m = this.nextU64() * n;
        low = m & MASK;
      }
    }
    return m >> 64n;
  }

  /** Advance the stream by z steps, discarding the output. */
  discard(z) {
    for (let i = 0n, n = BigInt(z); i < n; i++) this.nextU64();
  }

  [Symbol.iterator]() {
    return { next: () => ({ value: this.nextU64(), done: false }) };
  }
}

/** The heavier "strong" Cromulent variant. */
export class StrongEngine {
  #a;
  #b;

  constructor(seed = DEFAULT_SEED) {
    [this.#a, this.#b] = seedExpand(BigInt(seed));
  }

  /** Advance the state and return the next 64-bit output as a BigInt. */
  nextU64() {
    let a = this.#a;
    let b = this.#b;

    b = (b + rotl(a, 13n)) & MASK;
    a = (rotl(a, 29n) * C1 + b) & MASK;

    b = rotl(b, 17n) ^ a;
    a = (a + rotl((b * C2) & MASK, 31n)) & MASK;

    b = (b + rotl(a, 23n)) & MASK;
    a = rotl(a ^ b, 52n);

    const output = (a + rotl(b, 41n)) & MASK;

    this.#a = (a + C1) & MASK;
    this.#b = b ^ (a >> 17n);

    return mixFast(output);
  }

  discard(z) {
    for (let i = 0n, n = BigInt(z); i < n; i++) this.nextU64();
  }

  [Symbol.iterator]() {
    return { next: () => ({ value: this.nextU64(), done: false }) };
  }
}
