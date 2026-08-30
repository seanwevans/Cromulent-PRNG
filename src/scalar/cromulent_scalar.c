// src/scalar/cromulent_scalar.c

#include "cromulent.h"

static void store_le64(uint8_t *out, uint64_t x) {
  for (int i = 0; i < 8; i++) {
    out[i] = (uint8_t)(x & 0xff);
    x >>= 8;
  }
}

static uint64_t load_le64(const uint8_t *in) {
  uint64_t x = 0;
  for (int i = 0; i < 8; i++) {
    x |= ((uint64_t)in[i]) << (8 * i);
  }
  return x;
}

void cromulent_init(cromulent_state *state, const uint64_t seed) {
  uint64_t z = seed;

  z += C1;
  z = (z ^ (z >> 30)) * C2;
  z = (z ^ (z >> 27)) * C3;
  state->s0 = z ^ (z >> 31);

  z += C1;
  z = (z ^ (z >> 30)) * C2;
  z = (z ^ (z >> 27)) * C3;
  state->s1 = z ^ (z >> 31);
}

uint64_t cromulent_next(cromulent_state *state) {
  const uint64_t s0 = state->s0;
  const uint64_t s1 = state->s1;

  state->s0 = s0 * C6 + s1;
  state->s1 = rotl(s1, 31) + mix_fast(s0);

  uint64_t result = s0 + rotl(s1, 11);
  result ^= result >> 27;
  result *= C3;
  result ^= result >> 27;

  return result;
}

// Registry entry points. These wrap the same state and the same step function
// as cromulent_init/cromulent_next so that looking the generator up by name
// and calling it directly cannot produce different streams for one seed.
static cromulent_state registry_state;

void init_cromulent(uint64_t seed) { cromulent_init(&registry_state, seed); }

uint64_t cromulent128pp(void) { return cromulent_next(&registry_state); }

double cromulent_double(cromulent_state *state) {
  // Generate uniform double in [0, 1)
  return (cromulent_next(state) >> 11) * 0x1.0p-53;
}

float cromulent_float(cromulent_state *state) {
  // Generate uniform float in [0, 1)
  return (cromulent_next(state) >> 40) * 0x1.0p-24f;
}

#ifdef __SIZEOF_INT128__
uint64_t cromulent_range(cromulent_state *state, uint64_t n) {
  // Generate a uniform random number in [0, n). Returns 0 when n is 0.
  if (n == 0)
    return 0;
  uint64_t x = cromulent_next(state);
  __uint128_t m = (__uint128_t)x * n;
  uint64_t l = (uint64_t)m;

  if (l < n) {
    uint64_t t = (-n) % n;
    while (l < t) {
      x = cromulent_next(state);
      m = (__uint128_t)x * n;
      l = (uint64_t)m;
    }
  }

  return m >> 64;
}
#else
static void mul_u64(uint64_t a, uint64_t b, uint64_t *hi, uint64_t *lo) {
  cromulent_mul_u64_fallback(a, b, hi, lo);
}

uint64_t cromulent_range(cromulent_state *state, uint64_t n) {
  // Generate a uniform random number in [0, n). Returns 0 when n is 0.
  if (n == 0)
    return 0;
  uint64_t x = cromulent_next(state);
  uint64_t hi, lo;
  mul_u64(x, n, &hi, &lo);

  if (lo < n) {
    uint64_t t = (-n) % n;
    while (lo < t) {
      x = cromulent_next(state);
      mul_u64(x, n, &hi, &lo);
    }
  }

  return hi;
}
#endif

void cromulent_save(const cromulent_state *state, uint8_t *buffer) {
  store_le64(buffer, state->s0);
  store_le64(buffer + sizeof(uint64_t), state->s1);
}

void cromulent_load(cromulent_state *state, const uint8_t *buffer) {
  state->s0 = load_le64(buffer);
  state->s1 = load_le64(buffer + sizeof(uint64_t));
}
