// include/cromulent.h

#ifndef CROMULENT_H
#define CROMULENT_H

#include "internal.h"
#include <stddef.h>
#include <stdint.h>
#include <string.h>

typedef struct cromulent_state {
  uint64_t s0;
  uint64_t s1;
} cromulent_state;

typedef struct cromulent_strong_state {
  uint64_t a, b;
} cromulent_strong_state;

typedef struct {
  const char *name;
  void (*init)(uint64_t);
  uint64_t (*next)(void);
} CromulentPRNG;

typedef struct {
  __m256i s0, s1;
} cromulent_avx2_state;

void cromulent_init(cromulent_state *state, uint64_t seed);
uint64_t cromulent_next(cromulent_state *state);
double cromulent_double(cromulent_state *state);
float cromulent_float(cromulent_state *state);
void cromulent_jump(cromulent_state *state);
uint64_t cromulent_range(cromulent_state *state, uint64_t n);
void cromulent_save(const cromulent_state *state, uint8_t *buffer);
void cromulent_load(cromulent_state *state, const uint8_t *buffer);
const CromulentPRNG *cromulent_registry_find(const char *name);
const CromulentPRNG *cromulent_registry_all(size_t *count_out);

#endif // CROMULENT_H