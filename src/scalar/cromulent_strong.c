// scalar/cromulent_strong.c

#include "cromulent.h"

uint64_t cromulent_strong_next(cromulent_strong_state *state) {
  uint64_t a = state->a;
  uint64_t b = state->b;

  b += rotl(a, 13);
  a = rotl(a, 29) * C1 + b;

  b = rotl(b, 17) ^ a;
  a += rotl(b * C2, 31);

  b += rotl(a, 23);
  a = rotl(a ^ b, 52);

  const uint64_t output = a + rotl(b, 41);

  state->a = a + C1;
  state->b = b ^ (a >> 17);

  return mix_fast(output);
}

void cromulent_strong_init(cromulent_strong_state *st, uint64_t seed) {
  uint64_t z = seed;

  z += C1;
  z = (z ^ (z >> 30)) * C2;
  z = (z ^ (z >> 27)) * C3;
  st->a = z ^ (z >> 31);

  z += C1;
  z = (z ^ (z >> 30)) * C2;
  z = (z ^ (z >> 27)) * C3;
  st->b = z ^ (z >> 31);
}
