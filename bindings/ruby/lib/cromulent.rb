# frozen_string_literal: true

# The Cromulent PRNG -- a pure-Ruby port of the scalar reference generator.
#
# {Cromulent::Engine} reproduces the identical 64-bit stream as the C reference
# implementation (+cromulent_init+ / +cromulent_next+) for any given seed;
# {Cromulent::StrongEngine} mirrors the heavier +cromulent_strong+ variant.
#
# Ruby integers are arbitrary precision, so every operation is masked back to
# 64 bits with MASK to reproduce the wrapping arithmetic of the C generator.
module Cromulent
  MASK = (1 << 64) - 1

  C1 = 0x9e3779b97f4a7c15
  C2 = 0xbf58476d1ce4e5b9
  C3 = 0x94d049bb133111eb
  C6 = 0xd1342543de82ef95
  MH3 = 0xd6e8feb86659fd93

  # Default seed, shared with the C library.
  DEFAULT_SEED = 0x853c49e6748fea9b

  module_function

  def rotl(x, k)
    ((x << k) | (x >> (64 - k))) & MASK
  end

  def mix_fast(x)
    x ^= x >> 32
    x = (x * MH3) & MASK
    x ^= x >> 32
    x
  end

  # SplitMix64-style seed expansion, matching cromulent_init.
  def seed_expand(seed)
    z = seed & MASK
    out = []
    2.times do
      z = (z + C1) & MASK
      z = ((z ^ (z >> 30)) * C2) & MASK
      z = ((z ^ (z >> 27)) * C3) & MASK
      out << (z ^ (z >> 31))
    end
    out
  end

  # The primary Cromulent generator.
  class Engine
    def initialize(seed = DEFAULT_SEED)
      @s0, @s1 = Cromulent.seed_expand(seed)
    end

    attr_reader :s0, :s1

    # Advance the state and return the next 64-bit output.
    def next_u64
      s0 = @s0
      s1 = @s1

      @s0 = (s0 * C6 + s1) & MASK
      @s1 = (Cromulent.rotl(s1, 31) + Cromulent.mix_fast(s0)) & MASK

      result = (s0 + Cromulent.rotl(s1, 11)) & MASK
      result ^= result >> 27
      result = (result * C3) & MASK
      result ^= result >> 27
      result
    end

    # Uniform float in [0, 1) using the top 53 bits.
    def next_float
      (next_u64 >> 11) * (1.0 / (1 << 53))
    end

    # Unbiased uniform integer in [0, n) via Lemire's method. Returns 0 when n == 0.
    def bounded(n)
      return 0 if n.zero?

      m = next_u64 * n
      low = m & MASK
      if low < n
        threshold = ((1 << 64) - n) % n
        while low < threshold
          m = next_u64 * n
          low = m & MASK
        end
      end
      m >> 64
    end

    # Advance the stream by z steps, discarding the output.
    def discard(z)
      z.times { next_u64 }
    end

    def ==(other)
      other.is_a?(Engine) && @s0 == other.s0 && @s1 == other.s1
    end
  end

  # The heavier "strong" Cromulent variant.
  class StrongEngine
    def initialize(seed = DEFAULT_SEED)
      @a, @b = Cromulent.seed_expand(seed)
    end

    attr_reader :a, :b

    def next_u64
      a = @a
      b = @b

      b = (b + Cromulent.rotl(a, 13)) & MASK
      a = (Cromulent.rotl(a, 29) * C1 + b) & MASK

      b = Cromulent.rotl(b, 17) ^ a
      a = (a + Cromulent.rotl((b * C2) & MASK, 31)) & MASK

      b = (b + Cromulent.rotl(a, 23)) & MASK
      a = Cromulent.rotl(a ^ b, 52)

      output = (a + Cromulent.rotl(b, 41)) & MASK

      @a = (a + C1) & MASK
      @b = b ^ (a >> 17)

      Cromulent.mix_fast(output)
    end

    def discard(z)
      z.times { next_u64 }
    end

    def ==(other)
      other.is_a?(StrongEngine) && @a == other.a && @b == other.b
    end
  end
end
