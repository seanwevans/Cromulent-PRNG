// src/cromulent_registry.c
//
// A super-light “registry” that maps a short string to the
//   (init, next) function pair for each generator.
// It lets tools/tests pick a PRNG at run-time without if/else ladders.

#include "cromulent.h"
#include <stddef.h>
#include <string.h>

void init_xoshiro(uint64_t);
uint64_t xoshiro256pp(void);

void init_cromulent(uint64_t);
uint64_t cromulent128pp(void);

void init_splitmix64(uint64_t);
uint64_t splitmix64pp(void);

void init_pcg64(uint64_t);
uint64_t pcg64pp(void);

static const CromulentPRNG registry[] = {
    {"xoshiro256", init_xoshiro, xoshiro256pp},
    {"cromulent128", init_cromulent, cromulent128pp},
    {"splitmix64", init_splitmix64, splitmix64pp},
    {"pcg64", init_pcg64, pcg64pp},
    {NULL, NULL, NULL} // sentinel
};

const CromulentPRNG *cromulent_registry_find(const char *name) {
  for (size_t i = 0; registry[i].name; ++i)
    if (strcmp(registry[i].name, name) == 0)
      return &registry[i];
  return NULL; // not found
}

const CromulentPRNG *cromulent_registry_all(size_t *count_out) {
  if (count_out) {
    size_t n = 0;
    while (registry[n].name)
      ++n;
    *count_out = n;
  }
  return registry;
}
