// src/reference/splitmix64.c
#include "cromulent.h"

static uint64_t sm64_state;

void init_splitmix64(uint64_t seed) { sm64_state = seed; }

uint64_t splitmix64pp(void) {
  uint64_t z = (sm64_state += 0x9E3779B97F4A7C15ULL);
  z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ULL;
  z = (z ^ (z >> 27)) * 0x94D049BB133111EBULL;
  return z ^ (z >> 31);
}