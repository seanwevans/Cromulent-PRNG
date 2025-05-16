// apps/dump_raw.c

#include "cromulent.h"
#include <stdint.h>
#include <stdio.h>

static cromulent_state st;

int main(void) {
  cromulent_init(&st, 0xDEADBEEF);
  while (1) {
    uint64_t x = cromulent_next(&st);
    fwrite(&x, sizeof x, 1, stdout);
  }
}