-- Self-contained test for the Haskell Cromulent port. Verifies bit-for-bit
-- parity with the C reference vectors and basic range/discard behavior.
module Main (main) where

import Cromulent
import Data.IORef (modifyIORef', newIORef, readIORef)
import Data.List (foldl')
import Data.Word (Word64)
import System.Exit (exitFailure, exitSuccess)
import System.IO (hPutStrLn, stderr)

engineRef :: [Word64]
engineRef =
  [ 0x8b0849848b39737d, 0x829ecfb661e3a84d, 0x6cfb2afb89b5dc83
  , 0x8ad5c0d490669f95, 0x8d4459e6318f2474, 0xa0b907b845990f61
  , 0x2143675f2f4ff1ec, 0x38fff6f9c33c4f8f ]

strongRef :: [Word64]
strongRef =
  [ 0xa1e9fb73cc5c77fa, 0xd8bc61a96accc72e, 0x3f98dad0bcb1c8f3
  , 0xb179513c44fe1f0a, 0x413b884be5b9955f, 0x4b682d94916239a1
  , 0xe7b93a4600d77791, 0x6a54f95b111a3555 ]

-- Produce the first n outputs of an engine.
takeN :: Int -> Engine -> [Word64]
takeN 0 _ = []
takeN k e = let (x, e') = next e in x : takeN (k - 1) e'

takeStrong :: Int -> StrongEngine -> [Word64]
takeStrong 0 _ = []
takeStrong k e = let (x, e') = strongNext e in x : takeStrong (k - 1) e'

main :: IO ()
main = do
  failures <- newIORef (0 :: Int)
  let check cond msg =
        if cond then pure () else do
          hPutStrLn stderr ("FAIL: " ++ msg)
          modifyIORef' failures (+ 1)

  putStrLn "Running Cromulent Haskell engine tests"

  putStr "Testing engine matches C reference... "
  check (takeN 8 (mkEngine 0x0123456789ABCDEF) == engineRef) "engine outputs"
  putStrLn "OK"

  putStr "Testing strong engine matches C reference... "
  check (takeStrong 8 (mkStrongEngine 0x0123456789ABCDEF) == strongRef) "strong outputs"
  putStrLn "OK"

  putStr "Testing nextDouble range... "
  let (d0, e1) = nextDouble (mkEngine 42)
  check (abs (d0 - 0.42990649088115307) < 1e-15) "first double"
  let doubles = takeDoubles 10000 e1
  check (all (\v -> v >= 0.0 && v < 1.0) doubles) "doubles in range"
  putStrLn "OK"

  putStr "Testing bounded range... "
  let bs = takeBounded 10000 7 (mkEngine 99)
  check (all (< 7) bs) "bounded < 7"
  check (fst (bounded 0 (mkEngine 99)) == 0) "bounded 0"
  putStrLn "OK"

  putStr "Testing discard equivalence... "
  let ea = discard 50 (mkEngine 555)
      eb = foldl' (\e _ -> snd (next e)) (mkEngine 555) [1 .. 50 :: Int]
  check (takeN 100 ea == takeN 100 eb) "discard n == n calls"
  putStrLn "OK"

  n <- readIORef failures
  if n == 0
    then putStrLn "All Haskell engine tests passed successfully!" >> exitSuccess
    else putStrLn (show n ++ " check(s) failed!") >> exitFailure

takeDoubles :: Int -> Engine -> [Double]
takeDoubles 0 _ = []
takeDoubles k e = let (d, e') = nextDouble e in d : takeDoubles (k - 1) e'

takeBounded :: Int -> Word64 -> Engine -> [Word64]
takeBounded 0 _ _ = []
takeBounded k n e = let (v, e') = bounded n e in v : takeBounded (k - 1) n e'
