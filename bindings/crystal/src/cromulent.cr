# The Cromulent PRNG -- a Crystal port of the scalar reference generator.
#
# `Cromulent::Engine` reproduces the identical 64-bit stream as the C reference
# implementation (`cromulent_init` / `cromulent_next`) for any given seed;
# `Cromulent::StrongEngine` mirrors the heavier `cromulent_strong` variant.
#
# Crystal raises on arithmetic overflow, so the wrapping operators `&+`, `&-`,
# and `&*` are used to reproduce the mod-2^64 arithmetic of the C generator.
module Cromulent
  VERSION = "0.1.0"

  C1  = 0x9e3779b97f4a7c15_u64
  C2  = 0xbf58476d1ce4e5b9_u64
  C3  = 0x94d049bb133111eb_u64
  C6  = 0xd1342543de82ef95_u64
  MH3 = 0xd6e8feb86659fd93_u64

  # Default seed, shared with the C library.
  DEFAULT_SEED = 0x853c49e6748fea9b_u64

  def self.rotl(x : UInt64, k : Int32) : UInt64
    (x << k) | (x >> (64 - k))
  end

  def self.mix_fast(x : UInt64) : UInt64
    x ^= x >> 32
    x = x &* MH3
    x ^= x >> 32
    x
  end

  # SplitMix64-style seed expansion, matching cromulent_init.
  def self.seed_expand(seed : UInt64) : Tuple(UInt64, UInt64)
    z = seed
    v = StaticArray(UInt64, 2).new(0_u64)
    2.times do |i|
      z = z &+ C1
      z = (z ^ (z >> 30)) &* C2
      z = (z ^ (z >> 27)) &* C3
      v[i] = z ^ (z >> 31)
    end
    {v[0], v[1]}
  end

  # High 64 bits of the unsigned 128-bit product a*b (32-bit limbs).
  def self.umul_high(a : UInt64, b : UInt64) : UInt64
    a_lo = a & 0xffffffff_u64
    a_hi = a >> 32
    b_lo = b & 0xffffffff_u64
    b_hi = b >> 32
    lolo = a_lo &* b_lo
    hilo = a_hi &* b_lo
    lohi = a_lo &* b_hi
    hihi = a_hi &* b_hi
    carry = ((lolo >> 32) &+ (hilo & 0xffffffff_u64) &+ (lohi & 0xffffffff_u64)) >> 32
    hihi &+ (hilo >> 32) &+ (lohi >> 32) &+ carry
  end

  # The primary Cromulent generator.
  class Engine
    getter s0 : UInt64
    getter s1 : UInt64

    def initialize(seed : UInt64 = DEFAULT_SEED)
      @s0, @s1 = Cromulent.seed_expand(seed)
    end

    # Advance the state and return the next 64-bit output.
    def next_u64 : UInt64
      s0 = @s0
      s1 = @s1

      @s0 = s0 &* C6 &+ s1
      @s1 = Cromulent.rotl(s1, 31) &+ Cromulent.mix_fast(s0)

      result = s0 &+ Cromulent.rotl(s1, 11)
      result ^= result >> 27
      result = result &* C3
      result ^= result >> 27
      result
    end

    # Uniform Float64 in [0, 1) using the top 53 bits.
    def next_float : Float64
      (next_u64 >> 11).to_f64 * (1.0 / (1_u64 << 53).to_f64)
    end

    # Unbiased uniform integer in [0, n) via Lemire's method. Returns 0 when n == 0.
    def bounded(n : UInt64) : UInt64
      return 0_u64 if n == 0
      x = next_u64
      low = x &* n
      hi = Cromulent.umul_high(x, n)
      if low < n
        threshold = (0_u64 &- n) % n
        while low < threshold
          x = next_u64
          low = x &* n
          hi = Cromulent.umul_high(x, n)
        end
      end
      hi
    end

    # Advance the stream by z steps, discarding the output.
    def discard(z : UInt64) : Nil
      z.times { next_u64 }
    end

    def ==(other : Engine) : Bool
      @s0 == other.s0 && @s1 == other.s1
    end
  end

  # The heavier "strong" Cromulent variant.
  class StrongEngine
    getter a : UInt64
    getter b : UInt64

    def initialize(seed : UInt64 = DEFAULT_SEED)
      @a, @b = Cromulent.seed_expand(seed)
    end

    def next_u64 : UInt64
      a = @a
      b = @b

      b = b &+ Cromulent.rotl(a, 13)
      a = Cromulent.rotl(a, 29) &* C1 &+ b

      b = Cromulent.rotl(b, 17) ^ a
      a = a &+ Cromulent.rotl(b &* C2, 31)

      b = b &+ Cromulent.rotl(a, 23)
      a = Cromulent.rotl(a ^ b, 52)

      output = a &+ Cromulent.rotl(b, 41)

      @a = a &+ C1
      @b = b ^ (a >> 17)

      Cromulent.mix_fast(output)
    end

    def discard(z : UInt64) : Nil
      z.times { next_u64 }
    end

    def ==(other : StrongEngine) : Bool
      @a == other.a && @b == other.b
    end
  end
end
