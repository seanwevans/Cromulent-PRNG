// apps/bench_micro.c

#include "cromulent.h"
#include <stdint.h>
#include <inttypes.h>
#include <stdio.h>
#include <time.h>

#define NUM_SAMPLES 10000000000ULL

extern void init_xoshiro(uint64_t);
extern uint64_t xoshiro256pp(void);
extern void init_pcg64(uint64_t);
extern uint64_t pcg64pp(void);
extern void init_splitmix64(uint64_t);
extern uint64_t splitmix64pp(void);
extern void init_cromulent(uint64_t);
extern uint64_t cromulent128pp(void);

void benchmark(const char *name, void (*init)(uint64_t), uint64_t (*next)(void),
               uint64_t seed) {
  uint64_t dummy = 0;

  init(seed);
  struct timespec start, end;
  clock_gettime(CLOCK_MONOTONIC, &start);
  for (uint64_t i = 0; i < NUM_SAMPLES; i++) {
    dummy ^= next();
  }
  clock_gettime(CLOCK_MONOTONIC, &end);
  double time_ns =
      (end.tv_sec - start.tv_sec) * 1e9 + (end.tv_nsec - start.tv_nsec);
  printf("%-15s: %.2f ns/sample, dummy=%" PRIu64 "\n", name,
         time_ns / NUM_SAMPLES, dummy);
}

int main(void) {
  uint64_t seed = 69420;

  printf("running %llu samples with seed %" PRIu64 "\n", NUM_SAMPLES, seed);
  benchmark("xoshiro256", init_xoshiro, xoshiro256pp, seed);
  benchmark("cromulent128", init_cromulent, cromulent128pp, seed);
  benchmark("splitmix64", init_splitmix64, splitmix64pp, seed);
  benchmark("pcg64", init_pcg64, pcg64pp, seed);

  return 0;
}
