// src/simd/cromulent_avx2.c

#if defined(__AVX2__)
#include "cromulent.h"

static inline __m256i cromulent_avx2_next(cromulent_avx2_state *state) {
  __m256i s0 = state->s0;
  __m256i s1 = state->s1;

  // Parallel state update
  state->s0 = _mm256_add_epi64(
      _mm256_mullo_epi64(s0, _mm256_set1_epi64x(0xd1342543de82ef95ULL)), s1);

  state->s1 = _mm256_add_epi64(rotl_avx2(s1, 31), mix_avx2(s0));

  // Output mixing
  __m256i result = _mm256_add_epi64(s0, rotl_avx2(s1, 11));
  result = _mm256_xor_si256(result, _mm256_srli_epi64(result, 27));
  result =
      _mm256_mullo_epi64(result, _mm256_set1_epi64x(0x94d049bb133111ebULL));
  result = _mm256_xor_si256(result, _mm256_srli_epi64(result, 27));

  return result;
}
#endif
