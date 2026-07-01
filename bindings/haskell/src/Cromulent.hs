-- | The Cromulent PRNG — a Haskell port of the scalar reference generator.
--
-- 'Engine' reproduces the identical 64-bit stream as the C reference
-- implementation (@cromulent_init@ / @cromulent_next@) for any given seed;
-- 'StrongEngine' mirrors the heavier @cromulent_strong@ variant.
--
-- 'Word64' arithmetic is modular (wraps at 2^64), matching the C generator.
-- The engines are pure: each step returns the output together with the next
-- engine state.
module Cromulent
  ( Engine
  , StrongEngine
  , defaultSeed
  , mkEngine
  , next
  , nextDouble
  , bounded
  , discard
  , mkStrongEngine
  , strongNext
  , strongDiscard
  ) where

import Data.Bits (rotateL, shiftR, xor)
import Data.Word (Word64)

c1, c2, c3, c6, mh3 :: Word64
c1 = 0x9e3779b97f4a7c15
c2 = 0xbf58476d1ce4e5b9
c3 = 0x94d049bb133111eb
c6 = 0xd1342543de82ef95
mh3 = 0xd6e8feb86659fd93

-- | Default seed, shared with the C library.
defaultSeed :: Word64
defaultSeed = 0x853c49e6748fea9b

mixFast :: Word64 -> Word64
mixFast x0 = x2 `xor` (x2 `shiftR` 32)
  where
    x1 = x0 `xor` (x0 `shiftR` 32)
    x2 = x1 * mh3

-- | SplitMix64-style seed expansion, matching cromulent_init.
seedExpand :: Word64 -> (Word64, Word64)
seedExpand seed = (v0, v1)
  where
    step z0 = let z1 = z0 + c1
                  z2 = (z1 `xor` (z1 `shiftR` 30)) * c2
                  z3 = (z2 `xor` (z2 `shiftR` 27)) * c3
              in (z3 `xor` (z3 `shiftR` 31), z3)
    (v0, za) = step seed
    (v1, _) = step za

-- | The primary Cromulent engine.
data Engine = Engine !Word64 !Word64
  deriving (Eq, Show)

-- | Construct an engine seeded from a single 64-bit value.
mkEngine :: Word64 -> Engine
mkEngine seed = let (s0, s1) = seedExpand seed in Engine s0 s1

-- | Advance the state; return the output and the next engine.
next :: Engine -> (Word64, Engine)
next (Engine s0 s1) = (result, Engine s0' s1')
  where
    s0' = s0 * c6 + s1
    s1' = rotateL s1 31 + mixFast s0
    r0 = s0 + rotateL s1 11
    r1 = r0 `xor` (r0 `shiftR` 27)
    r2 = r1 * c3
    result = r2 `xor` (r2 `shiftR` 27)

-- | Uniform Double in [0, 1) using the top 53 bits.
nextDouble :: Engine -> (Double, Engine)
nextDouble e = (fromIntegral (x `shiftR` 11) / 9007199254740992, e')
  where (x, e') = next e

-- | Unbiased uniform integer in [0, n) via Lemire's method. Returns 0 when n == 0.
bounded :: Word64 -> Engine -> (Word64, Engine)
bounded n e0
  | n == 0 = (0, e0)
  | otherwise = go (next e0)
  where
    threshold = fromInteger ((2 ^ (64 :: Int) - toInteger n) `mod` toInteger n) :: Word64
    go (x, e) =
      let m = toInteger x * toInteger n
          low = fromInteger m :: Word64
          hi = fromInteger (m `div` (2 ^ (64 :: Int))) :: Word64
      in if low < threshold then go (next e) else (hi, e)

-- | Advance the stream by k steps, discarding the output.
discard :: Word64 -> Engine -> Engine
discard 0 e = e
discard k e = discard (k - 1) (snd (next e))

-- | The heavier "strong" Cromulent variant.
data StrongEngine = StrongEngine !Word64 !Word64
  deriving (Eq, Show)

mkStrongEngine :: Word64 -> StrongEngine
mkStrongEngine seed = let (a, b) = seedExpand seed in StrongEngine a b

strongNext :: StrongEngine -> (Word64, StrongEngine)
strongNext (StrongEngine a0 b0) = (mixFast output, StrongEngine a' b')
  where
    b1 = b0 + rotateL a0 13
    a1 = rotateL a0 29 * c1 + b1
    b2 = rotateL b1 17 `xor` a1
    a2 = a1 + rotateL (b2 * c2) 31
    b3 = b2 + rotateL a2 23
    a3 = rotateL (a2 `xor` b3) 52
    output = a3 + rotateL b3 41
    a' = a3 + c1
    b' = b3 `xor` (a3 `shiftR` 17)

strongDiscard :: Word64 -> StrongEngine -> StrongEngine
strongDiscard 0 e = e
strongDiscard k e = strongDiscard (k - 1) (snd (strongNext e))
