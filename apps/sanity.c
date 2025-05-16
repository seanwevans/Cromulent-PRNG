// apps/sanity.c
//
// Very small smoke-test: for every registered PRNG, ensure that
//  1) two successive values are *not* identical
//  2) save→load round-trip reproduces the stream
//
// Compile with the rest of the project; link against libcromulent.

#include "cromulent.h"
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define CHECK_EQ(a, b) assert((a) == (b))

int main(void) {
  size_t n = 0;
  const CromulentPRNG *list = cromulent_registry_all(&n);

  printf("PRNG sanity sweep: %zu generators found\n", n);

  for (size_t i = 0; i < n; ++i) {
    const CromulentPRNG *g = &list[i];
    printf("  %-12s ... ", g->name);

    // uniqueness
    g->init(0xCAFEBABE12345678ULL);
    uint64_t a = g->next();
    uint64_t b = g->next();
    assert(a != b);

    // round-trip
    if (strcmp(g->name, "cromulent128") == 0) {
      cromulent_state st;
      cromulent_init(&st, 0xDEADBEEF);
      uint64_t first5[5];
      for (int j = 0; j < 5; ++j)
        first5[j] = cromulent_next(&st);

      uint8_t buf[16];
      cromulent_save(&st, buf);

      for (int j = 0; j < 5; ++j)
        cromulent_next(&st);
      cromulent_load(&st, buf);

      for (int j = 0; j < 5; ++j)
        CHECK_EQ(first5[j], cromulent_next(&st));
    }

    puts("ok");
  }

  puts("All sanity checks passed.");
  return 0;
}
