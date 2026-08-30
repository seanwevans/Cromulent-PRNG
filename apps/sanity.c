// apps/sanity.c
//
// Very small smoke-test:
//  1) for every registered PRNG, two successive values are *not* identical
//  2) cromulent128's save→load round-trip reproduces the stream
//
// The checks are deliberately plain `if`s rather than assert(): the project's
// own CI configures -DCMAKE_BUILD_TYPE=Release, which defines NDEBUG and would
// compile every assert() away, leaving this program a no-op that always
// "passes".
//
// Compile with the rest of the project; link against libcromulent.

#include "cromulent.h"
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

static int failures = 0;

static void check(int cond, const char *msg) {
  if (!cond) {
    fprintf(stderr, "FAIL: %s\n", msg);
    ++failures;
  }
}

// Every registered generator must advance: two successive draws differ.
static void check_registry_advances(void) {
  size_t n = 0;
  const CromulentPRNG *list = cromulent_registry_all(&n);

  printf("PRNG sanity sweep: %zu generators found\n", n);
  check(n > 0, "registry should not be empty");

  for (size_t i = 0; i < n; ++i) {
    const CromulentPRNG *g = &list[i];
    printf("  %-12s ... ", g->name);

    g->init(0xCAFEBABE12345678ULL);
    const uint64_t a = g->next();
    const uint64_t b = g->next();
    check(a != b, g->name);

    puts("ok");
  }
}

// Saving mid-stream and reloading must reproduce the following outputs.
static void check_save_load_round_trip(void) {
  printf("  %-12s ... ", "save/load");

  cromulent_state st;
  cromulent_init(&st, 0xDEADBEEF);

  for (int j = 0; j < 5; ++j)
    cromulent_next(&st); // warm up

  uint8_t buf[16];
  cromulent_save(&st, buf);

  uint64_t expected[5];
  for (int j = 0; j < 5; ++j)
    expected[j] = cromulent_next(&st);

  cromulent_load(&st, buf);

  for (int j = 0; j < 5; ++j) {
    const uint64_t got = cromulent_next(&st);
    if (got != expected[j]) {
      fprintf(stderr,
              "FAIL: save/load draw %d: expected 0x%016" PRIx64
              ", got 0x%016" PRIx64 "\n",
              j, expected[j], got);
      ++failures;
    }
  }

  puts("ok");
}

int main(void) {
  check_registry_advances();
  check_save_load_round_trip();

  if (failures != 0) {
    printf("%d sanity check(s) failed!\n", failures);
    return 1;
  }

  puts("All sanity checks passed.");
  return 0;
}
