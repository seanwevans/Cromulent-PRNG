## The Cromulent PRNG -- a Nim port of the scalar reference generator.
##
## `CromulentEngine` reproduces the identical 64-bit stream as the C reference
## implementation (`cromulent_init` / `cromulent_next`) for any given seed;
## `StrongEngine` mirrors the heavier `cromulent_strong` variant. Nim's
## `uint64` wraps on overflow, matching the C generator exactly.

import std/bitops

const
  C1 = 0x9e3779b97f4a7c15'u64
  C2 = 0xbf58476d1ce4e5b9'u64
  C3 = 0x94d049bb133111eb'u64
  C6 = 0xd1342543de82ef95'u64
  MH3 = 0xd6e8feb86659fd93'u64

  ## Default seed, shared with the C library.
  DefaultSeed* = 0x853c49e6748fea9b'u64

type
  CromulentEngine* = object
    s0, s1: uint64
  StrongEngine* = object
    a, b: uint64

func mixFast(x0: uint64): uint64 =
  var x = x0
  x = x xor (x shr 32)
  x = x * MH3
  x = x xor (x shr 32)
  x

## SplitMix64-style seed expansion, matching cromulent_init.
func seedExpand(seed: uint64): (uint64, uint64) =
  var z = seed
  var outv: array[2, uint64]
  for i in 0 ..< 2:
    z = z + C1
    z = (z xor (z shr 30)) * C2
    z = (z xor (z shr 27)) * C3
    outv[i] = z xor (z shr 31)
  (outv[0], outv[1])

## High 64 bits of the unsigned 128-bit product a*b (32-bit limbs).
func umulHigh(a, b: uint64): uint64 =
  let
    aLo = a and 0xffffffff'u64
    aHi = a shr 32
    bLo = b and 0xffffffff'u64
    bHi = b shr 32
    lolo = aLo * bLo
    hilo = aHi * bLo
    lohi = aLo * bHi
    hihi = aHi * bHi
    carry = ((lolo shr 32) + (hilo and 0xffffffff'u64) + (lohi and 0xffffffff'u64)) shr 32
  hihi + (hilo shr 32) + (lohi shr 32) + carry

## Construct an engine seeded from a single 64-bit value.
func initEngine*(seed: uint64 = DefaultSeed): CromulentEngine =
  (result.s0, result.s1) = seedExpand(seed)

## Advance the state and return the next 64-bit output.
func next*(e: var CromulentEngine): uint64 =
  let
    s0 = e.s0
    s1 = e.s1
  e.s0 = s0 * C6 + s1
  e.s1 = rotateLeftBits(s1, 31) + mixFast(s0)
  var r = s0 + rotateLeftBits(s1, 11)
  r = r xor (r shr 27)
  r = r * C3
  r = r xor (r shr 27)
  r

## Uniform float in [0, 1) using the top 53 bits.
func nextFloat*(e: var CromulentEngine): float64 =
  float64(e.next shr 11) * (1.0 / float64(1'u64 shl 53))

## Unbiased uniform integer in [0, n) via Lemire's method. Returns 0 when n == 0.
func bounded*(e: var CromulentEngine, n: uint64): uint64 =
  if n == 0'u64:
    return 0'u64
  var
    x = e.next
    low = x * n
    hi = umulHigh(x, n)
  if low < n:
    let threshold = (0'u64 - n) mod n
    while low < threshold:
      x = e.next
      low = x * n
      hi = umulHigh(x, n)
  hi

## Advance the stream by z steps, discarding the output.
func skip*(e: var CromulentEngine, z: uint64) =
  for _ in 0'u64 ..< z:
    discard e.next

## Construct a strong engine seeded from a single 64-bit value.
func initStrongEngine*(seed: uint64 = DefaultSeed): StrongEngine =
  (result.a, result.b) = seedExpand(seed)

func next*(e: var StrongEngine): uint64 =
  var
    a = e.a
    b = e.b
  b = b + rotateLeftBits(a, 13)
  a = rotateLeftBits(a, 29) * C1 + b
  b = rotateLeftBits(b, 17) xor a
  a = a + rotateLeftBits(b * C2, 31)
  b = b + rotateLeftBits(a, 23)
  a = rotateLeftBits(a xor b, 52)
  let output = a + rotateLeftBits(b, 41)
  e.a = a + C1
  e.b = b xor (a shr 17)
  mixFast(output)

func skip*(e: var StrongEngine, z: uint64) =
  for _ in 0'u64 ..< z:
    discard e.next
