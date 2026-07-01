// include/cromulent.hpp
//
// C++ interface for the Cromulent PRNG.
//
// This is a header-only, standalone implementation that mirrors the scalar C
// generator bit-for-bit (see src/scalar/cromulent_scalar.c). The engines model
// the standard C++ named requirements:
//
//   * UniformRandomBitGenerator  -> usable with <random> distributions
//   * RandomNumberEngine         -> seedable, serializable, comparable
//
// so they interoperate directly with std::uniform_int_distribution,
// std::uniform_real_distribution, std::shuffle, std::sample, etc.
//
// Resource management follows the rule of zero: the state is a pair of value
// members, so construction, copy, move, and destruction are all trivially and
// correctly handled by the compiler. There are no owning pointers, no manual
// new/delete, and every object is fully initialized by its constructor.

#ifndef CROMULENT_HPP
#define CROMULENT_HPP

#include <cstdint>
#include <cstddef>
#include <array>
#include <istream>
#include <limits>
#include <ostream>
#include <type_traits>

namespace cromulent {

namespace detail {

inline constexpr std::uint64_t C1 = 0x9e3779b97f4a7c15ULL;
inline constexpr std::uint64_t C2 = 0xbf58476d1ce4e5b9ULL;
inline constexpr std::uint64_t C3 = 0x94d049bb133111ebULL;
inline constexpr std::uint64_t C6 = 0xd1342543de82ef95ULL;
inline constexpr std::uint64_t MH3 = 0xd6e8feb86659fd93ULL;

[[nodiscard]] constexpr std::uint64_t rotl(std::uint64_t x, int k) noexcept {
  return (x << k) | (x >> (64 - k));
}

[[nodiscard]] constexpr std::uint64_t mix_fast(std::uint64_t x) noexcept {
  x ^= x >> 32;
  x *= MH3;
  x ^= x >> 32;
  return x;
}

// SplitMix64-style seed expansion, matching cromulent_init in the C library.
[[nodiscard]] constexpr std::uint64_t seed_step(std::uint64_t &z) noexcept {
  z += C1;
  z = (z ^ (z >> 30)) * C2;
  z = (z ^ (z >> 27)) * C3;
  return z ^ (z >> 31);
}

} // namespace detail

// The primary Cromulent engine. Equivalent to the scalar C generator:
// cromulent_init / cromulent_next produce the identical stream for a given
// 64-bit seed.
class engine {
public:
  using result_type = std::uint64_t;

  static constexpr result_type default_seed = 0x853c49e6748fea9bULL;

  [[nodiscard]] static constexpr result_type min() noexcept { return 0; }
  [[nodiscard]] static constexpr result_type max() noexcept {
    return std::numeric_limits<result_type>::max();
  }

  // Seed from a single 64-bit value. Matches cromulent_init exactly.
  explicit engine(result_type value = default_seed) noexcept { seed(value); }

  // Seed from a standard SeedSequence (e.g. std::seed_seq, std::random_device
  // wrapper). SFINAE keeps this from hijacking the integer-seed constructor.
  template <class Sseq,
            typename = std::enable_if_t<
                !std::is_convertible_v<Sseq &, result_type> &&
                !std::is_same_v<std::remove_cv_t<std::remove_reference_t<Sseq>>,
                                engine>>>
  explicit engine(Sseq &q) {
    seed(q);
  }

  void seed(result_type value = default_seed) noexcept {
    std::uint64_t z = value;
    s0_ = detail::seed_step(z);
    s1_ = detail::seed_step(z);
  }

  template <class Sseq>
  auto seed(Sseq &q)
      -> std::enable_if_t<!std::is_convertible_v<Sseq &, result_type>> {
    std::array<std::uint32_t, 4> words{};
    q.generate(words.begin(), words.end());
    s0_ = (static_cast<std::uint64_t>(words[1]) << 32) | words[0];
    s1_ = (static_cast<std::uint64_t>(words[3]) << 32) | words[2];
    // Avoid the degenerate all-zero state.
    if ((s0_ | s1_) == 0)
      s1_ = detail::C1;
  }

  // Advance the state and return the next 64-bit output. Mirrors
  // cromulent_next byte-for-byte.
  result_type operator()() noexcept {
    const std::uint64_t s0 = s0_;
    const std::uint64_t s1 = s1_;

    s0_ = s0 * detail::C6 + s1;
    s1_ = detail::rotl(s1, 31) + detail::mix_fast(s0);

    std::uint64_t result = s0 + detail::rotl(s1, 11);
    result ^= result >> 27;
    result *= detail::C3;
    result ^= result >> 27;
    return result;
  }

  // Advance the stream by z steps, discarding the output.
  void discard(unsigned long long z) noexcept {
    while (z-- != 0)
      (void)(*this)();
  }

  // Uniform double in [0, 1) using the top 53 bits.
  [[nodiscard]] double next_double() noexcept {
    return static_cast<double>((*this)() >> 11) * 0x1.0p-53;
  }

  // Uniform float in [0, 1) using the top 24 bits.
  [[nodiscard]] float next_float() noexcept {
    return static_cast<float>((*this)() >> 40) * 0x1.0p-24f;
  }

  // Unbiased uniform integer in [0, n) via Lemire's method. Returns 0 when
  // n == 0. Provided as a fast path; std::uniform_int_distribution also works.
  [[nodiscard]] result_type bounded(result_type n) noexcept {
    if (n == 0)
      return 0;
    __extension__ using u128 = unsigned __int128;
    result_type x = (*this)();
    u128 m = static_cast<u128>(x) * n;
    result_type low = static_cast<result_type>(m);
    if (low < n) {
      const result_type threshold = (0u - n) % n;
      while (low < threshold) {
        x = (*this)();
        m = static_cast<u128>(x) * n;
        low = static_cast<result_type>(m);
      }
    }
    return static_cast<result_type>(m >> 64);
  }

  [[nodiscard]] friend bool operator==(const engine &a,
                                       const engine &b) noexcept {
    return a.s0_ == b.s0_ && a.s1_ == b.s1_;
  }
  [[nodiscard]] friend bool operator!=(const engine &a,
                                       const engine &b) noexcept {
    return !(a == b);
  }

  // Text serialization compatible with the standard engine convention.
  template <class CharT, class Traits>
  friend std::basic_ostream<CharT, Traits> &
  operator<<(std::basic_ostream<CharT, Traits> &os, const engine &e) {
    return os << e.s0_ << ' ' << e.s1_;
  }

  template <class CharT, class Traits>
  friend std::basic_istream<CharT, Traits> &
  operator>>(std::basic_istream<CharT, Traits> &is, engine &e) {
    std::uint64_t s0 = 0, s1 = 0;
    if (is >> s0 >> s1) {
      e.s0_ = s0;
      e.s1_ = s1;
    }
    return is;
  }

private:
  std::uint64_t s0_ = 0;
  std::uint64_t s1_ = 0;
};

// The "strong" variant: a heavier permutation with the same interface. Mirrors
// cromulent_strong_init / cromulent_strong_next.
class strong_engine {
public:
  using result_type = std::uint64_t;

  static constexpr result_type default_seed = 0x853c49e6748fea9bULL;

  [[nodiscard]] static constexpr result_type min() noexcept { return 0; }
  [[nodiscard]] static constexpr result_type max() noexcept {
    return std::numeric_limits<result_type>::max();
  }

  explicit strong_engine(result_type value = default_seed) noexcept {
    seed(value);
  }

  void seed(result_type value = default_seed) noexcept {
    std::uint64_t z = value;
    a_ = detail::seed_step(z);
    b_ = detail::seed_step(z);
  }

  result_type operator()() noexcept {
    std::uint64_t a = a_;
    std::uint64_t b = b_;

    b += detail::rotl(a, 13);
    a = detail::rotl(a, 29) * detail::C1 + b;

    b = detail::rotl(b, 17) ^ a;
    a += detail::rotl(b * detail::C2, 31);

    b += detail::rotl(a, 23);
    a = detail::rotl(a ^ b, 52);

    const std::uint64_t output = a + detail::rotl(b, 41);

    a_ = a + detail::C1;
    b_ = b ^ (a >> 17);

    return detail::mix_fast(output);
  }

  void discard(unsigned long long z) noexcept {
    while (z-- != 0)
      (void)(*this)();
  }

  [[nodiscard]] friend bool operator==(const strong_engine &x,
                                       const strong_engine &y) noexcept {
    return x.a_ == y.a_ && x.b_ == y.b_;
  }
  [[nodiscard]] friend bool operator!=(const strong_engine &x,
                                       const strong_engine &y) noexcept {
    return !(x == y);
  }

  template <class CharT, class Traits>
  friend std::basic_ostream<CharT, Traits> &
  operator<<(std::basic_ostream<CharT, Traits> &os, const strong_engine &e) {
    return os << e.a_ << ' ' << e.b_;
  }

  template <class CharT, class Traits>
  friend std::basic_istream<CharT, Traits> &
  operator>>(std::basic_istream<CharT, Traits> &is, strong_engine &e) {
    std::uint64_t a = 0, b = 0;
    if (is >> a >> b) {
      e.a_ = a;
      e.b_ = b;
    }
    return is;
  }

private:
  std::uint64_t a_ = 0;
  std::uint64_t b_ = 0;
};

} // namespace cromulent

#endif // CROMULENT_HPP
