// src/simd/cromulent_avx2.c

#if defined(__AVX2__)
#include "cromulent.h"

void cromulent_avx2_init(cromulent_avx2_state *state, uint64_t seed) {
  uint64_t z = seed;
  uint64_t buf[8];

  for (int i = 0; i < 8; ++i) {
    z += C1;
    z = (z ^ (z >> 30)) * C2;
    z = (z ^ (z >> 27)) * C3;
    buf[i] = z ^ (z >> 31);
  }

  state->s0 = _mm256_set_epi64x(buf[3], buf[2], buf[1], buf[0]);
  state->s1 = _mm256_set_epi64x(buf[7], buf[6], buf[5], buf[4]);
}

__m256i cromulent_avx2_next(cromulent_avx2_state *state) {
  __m256i s0 = state->s0;
  __m256i s1 = state->s1;

  state->s0 =
      _mm256_add_epi64(mullo_epi64_avx2(s0, _mm256_set1_epi64x(0xd1342543de82ef95ULL)),
                       s1);
  state->s1 = _mm256_add_epi64(rotl_avx2(s1, 31), mix_avx2(s0));

  __m256i result = _mm256_add_epi64(s0, rotl_avx2(s1, 11));
  result = _mm256_xor_si256(result, _mm256_srli_epi64(result, 27));
  result =
      mullo_epi64_avx2(result, _mm256_set1_epi64x(0x94d049bb133111ebULL));
  result = _mm256_xor_si256(result, _mm256_srli_epi64(result, 27));

  return result;
}

#endif // __AVX2__
