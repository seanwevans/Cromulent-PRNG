// tests/unit/cpp_engine.cpp
//
// Verifies the C++ engine against the C reference implementation and exercises
// its standard-library integration (UniformRandomBitGenerator / RandomNumberEngine).

#include "cromulent.hpp"

extern "C" {
#include "cromulent.h"
}

#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <numeric>
#include <random>
#include <sstream>
#include <vector>

#define CHECK(cond, msg)                                                        \
  do {                                                                          \
    if (!(cond)) {                                                              \
      std::fprintf(stderr, "FAIL: %s at line %d: %s\n", __FILE__, __LINE__,     \
                   msg);                                                        \
      return 1;                                                                 \
    }                                                                           \
  } while (0)

static int test_matches_c_reference() {
  std::printf("Testing C++ engine matches C reference... ");

  const std::uint64_t seeds[] = {0, 1, 0xDEADBEEF, 0xCAFEBABE12345678ULL,
                                 0xFFFFFFFFFFFFFFFFULL};
  for (std::uint64_t seed : seeds) {
    cromulent_state c_state;
    cromulent_init(&c_state, seed);

    cromulent::engine cpp_engine(seed);

    for (int i = 0; i < 1000; ++i) {
      std::uint64_t c_val = cromulent_next(&c_state);
      std::uint64_t cpp_val = cpp_engine();
      CHECK(c_val == cpp_val, "C++ output must match C output");
    }
  }

  std::printf("OK\n");
  return 0;
}

static int test_strong_matches_c_reference() {
  std::printf("Testing C++ strong_engine matches C reference... ");

  cromulent_strong_state c_state;
  cromulent_strong_init(&c_state, 0xABCDEF0123456789ULL);

  cromulent::strong_engine cpp_engine(0xABCDEF0123456789ULL);

  for (int i = 0; i < 1000; ++i) {
    std::uint64_t c_val = cromulent_strong_next(&c_state);
    std::uint64_t cpp_val = cpp_engine();
    CHECK(c_val == cpp_val, "C++ strong output must match C output");
  }

  std::printf("OK\n");
  return 0;
}

static int test_urbg_requirements() {
  std::printf("Testing UniformRandomBitGenerator integration... ");

  static_assert(cromulent::engine::min() == 0, "min must be 0");
  static_assert(cromulent::engine::max() == UINT64_MAX, "max must be UINT64_MAX");

  cromulent::engine e(12345);

  // Works with standard distributions.
  std::uniform_int_distribution<int> dist(1, 6);
  for (int i = 0; i < 1000; ++i) {
    int roll = dist(e);
    CHECK(roll >= 1 && roll <= 6, "distribution must respect bounds");
  }

  // Works with standard algorithms.
  std::vector<int> v(100);
  std::iota(v.begin(), v.end(), 0);
  std::shuffle(v.begin(), v.end(), e);
  std::vector<int> sorted = v;
  std::sort(sorted.begin(), sorted.end());
  for (int i = 0; i < 100; ++i)
    CHECK(sorted[i] == i, "shuffle must be a permutation");

  std::printf("OK\n");
  return 0;
}

static int test_serialization_roundtrip() {
  std::printf("Testing serialization round-trip... ");

  cromulent::engine e(0x1234567890ABCDEFULL);
  e.discard(37);

  std::stringstream ss;
  ss << e;

  cromulent::engine restored;
  ss >> restored;

  CHECK(e == restored, "restored engine must equal original");

  for (int i = 0; i < 100; ++i)
    CHECK(e() == restored(), "restored stream must match original");

  std::printf("OK\n");
  return 0;
}

static int test_seed_seq() {
  std::printf("Testing seed_seq construction... ");

  std::seed_seq seq{1, 2, 3, 4};
  cromulent::engine a(seq);
  cromulent::engine b(seq);
  CHECK(a == b, "same seed_seq must produce identical engines");

  bool differs = false;
  for (int i = 0; i < 10; ++i)
    if (a() != cromulent::engine(42)())
      differs = true;
  CHECK(differs, "seed_seq engine should differ from integer-seeded engine");

  std::printf("OK\n");
  return 0;
}

static int test_bounded() {
  std::printf("Testing bounded() range and n==0... ");

  cromulent::engine e(99);
  CHECK(e.bounded(0) == 0, "bounded(0) must return 0");
  for (int i = 0; i < 10000; ++i) {
    std::uint64_t v = e.bounded(7);
    CHECK(v < 7, "bounded(7) must be < 7");
  }

  std::printf("OK\n");
  return 0;
}

static int test_discard_equivalence() {
  std::printf("Testing discard equivalence... ");

  cromulent::engine a(555), b(555);
  a.discard(50);
  for (int i = 0; i < 50; ++i)
    (void)b();
  CHECK(a == b, "discard(n) must equal n calls");

  std::printf("OK\n");
  return 0;
}

int main() {
  std::printf("Running Cromulent C++ engine tests\n");

  int result = 0;
  result |= test_matches_c_reference();
  result |= test_strong_matches_c_reference();
  result |= test_urbg_requirements();
  result |= test_serialization_roundtrip();
  result |= test_seed_seq();
  result |= test_bounded();
  result |= test_discard_equivalence();

  if (result == 0) {
    std::printf("All C++ engine tests passed successfully!\n");
    return 0;
  }
  std::printf("Some tests failed!\n");
  return 1;
}
