// include/internal.h

#ifndef CROMULENT_INTERNAL
#define CROMULENT_INTERNAL

#include <stdint.h>
#if defined(__x86_64__) || defined(_M_X64)
#include <immintrin.h>
#endif

#define C1 0x9e3779b97f4a7c15ULL
#define C2 0xbf58476d1ce4e5b9ULL
#define C3 0x94d049bb133111ebULL
#define C4 0xff51afd7ed558ccdULL
#define C5 0xc4ceb9fe1a85ec53ULL
#define C6 0xd1342543de82ef95ULL

#define SC1 0x3b22c4a0c50de29bULL
#define SC2 0x5e4d93b362c7f62aULL

#define MH3 0xd6e8feb86659fd93ULL

#if defined(__AVX2__)
static inline __m256i rotl_avx2(__m256i x, int k) {
  return _mm256_or_si256(_mm256_slli_epi64(x, k), _mm256_srli_epi64(x, 64 - k));
}

static inline __m256i mix_avx2(__m256i x) {
  x = _mm256_xor_si256(x, _mm256_srli_epi64(x, 33));
  x = _mm256_mullo_epi64(x, _mm256_set1_epi64x(0xff51afd7ed558ccdULL));
  x = _mm256_xor_si256(x, _mm256_srli_epi64(x, 33));
  x = _mm256_mullo_epi64(x, _mm256_set1_epi64x(0xc4ceb9fe1a85ec53ULL));
  x = _mm256_xor_si256(x, _mm256_srli_epi64(x, 33));
  return x;
}
#endif

static inline uint64_t rotl(const uint64_t x, int k) {
  return (x << k) | (x >> (64 - k));
}

static inline uint64_t rotr(const uint64_t x, int k) {
  return (x >> k) | (x << (64 - k));
}

static inline uint64_t diffuse(const uint64_t x, const uint64_t y) {
  return rotl(x * C1, 23) + rotl(y * C2, 31);
}

static inline uint64_t mix(uint64_t x) {
  x ^= x >> 33;
  x *= C4;
  x ^= x >> 33;
  x *= C5;
  x ^= x >> 33;
  return x;
}

static inline uint64_t mix_fast(uint64_t x) {
  x ^= x >> 32;
  x *= MH3;
  x ^= x >> 32;
  return x;
}

#endif // CROMULENT_INTERNAL