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

static inline __m256i mullo_epi64_avx2(__m256i a, __m256i b) {
  __m256i albl = _mm256_mul_epu32(a, b);
  __m256i albh = _mm256_mul_epu32(a, _mm256_srli_epi64(b, 32));
  __m256i ahbl = _mm256_mul_epu32(_mm256_srli_epi64(a, 32), b);
  __m256i cross = _mm256_add_epi64(albh, ahbl);
  cross = _mm256_slli_epi64(cross, 32);
  return _mm256_add_epi64(albl, cross);
}

static inline __m256i mix_avx2(__m256i x) {
  x = _mm256_xor_si256(x, _mm256_srli_epi64(x, 33));
  x = mullo_epi64_avx2(x, _mm256_set1_epi64x(0xff51afd7ed558ccdULL));
  x = _mm256_xor_si256(x, _mm256_srli_epi64(x, 33));
  x = mullo_epi64_avx2(x, _mm256_set1_epi64x(0xc4ceb9fe1a85ec53ULL));
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

static inline void cromulent_mul_u64_fallback(uint64_t a, uint64_t b,
                                              uint64_t *hi, uint64_t *lo) {
  const uint64_t mask32 = 0xffffffffULL;
  const uint64_t a_lo = a & mask32;
  const uint64_t a_hi = a >> 32;
  const uint64_t b_lo = b & mask32;
  const uint64_t b_hi = b >> 32;

  const uint64_t p0 = a_lo * b_lo;
  const uint64_t p1 = a_lo * b_hi;
  const uint64_t p2 = a_hi * b_lo;
  const uint64_t p3 = a_hi * b_hi;

  uint64_t low = p0;
  uint64_t carry = 0;

  const uint64_t cross1 = (p1 & mask32) << 32;
  low += cross1;
  if (low < cross1)
    carry++;

  const uint64_t cross2 = (p2 & mask32) << 32;
  uint64_t new_low = low + cross2;
  if (new_low < cross2)
    carry++;

  low = new_low;
  *lo = low;
  *hi = p3 + (p1 >> 32) + (p2 >> 32) + carry;
}

#endif // CROMULENT_INTERNAL
