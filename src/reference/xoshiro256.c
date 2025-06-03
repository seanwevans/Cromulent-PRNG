// xoshiro.c
#include "cromulent.h"

static uint64_t s[4];

uint64_t xoshiro256pp(void) {
  const uint64_t result = rotl(s[0] + s[3], 23) + s[0];
  const uint64_t t = s[1] << 17;

  s[2] ^= s[0];
  s[3] ^= s[1];
  s[1] ^= s[2];
  s[0] ^= s[3];
  s[2] ^= t;
  s[3] = rotl(s[3], 45);
  return result;
}

void init_xoshiro(uint64_t seed) {
  for (int i = 0; i < 4; ++i)
    s[i] = seed ^ (i * C1);
}
