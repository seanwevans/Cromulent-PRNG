// pcg64.c

#include "cromulent.h"

static uint64_t pcg_state = 0x853c49e6748fea9bULL;
static uint64_t pcg_inc = 0xda3e39cb94b95bdbULL;

void init_pcg64(uint64_t seed) {
  init_splitmix64(seed);
  pcg_state = splitmix64pp();
  pcg_inc = splitmix64pp() | 1u;
}

uint64_t pcg64pp(void) {
  uint64_t oldstate = pcg_state;
  pcg_state = oldstate * 6364136223846793005ULL + pcg_inc;
  uint64_t xorshifted = ((oldstate >> 18u) ^ oldstate) >> 27u;
  uint64_t rot = oldstate >> 59u;
  return (xorshifted >> rot) | (xorshifted << ((-rot) & 31));
}
