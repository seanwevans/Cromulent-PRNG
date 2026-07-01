## Self-contained test for the Nim Cromulent port. Verifies bit-for-bit parity
## with the C reference vectors and basic range/skip behavior.

import ../src/cromulent

const
  engineRef = [
    0x8b0849848b39737d'u64, 0x829ecfb661e3a84d'u64, 0x6cfb2afb89b5dc83'u64,
    0x8ad5c0d490669f95'u64, 0x8d4459e6318f2474'u64, 0xa0b907b845990f61'u64,
    0x2143675f2f4ff1ec'u64, 0x38fff6f9c33c4f8f'u64]
  strongRef = [
    0xa1e9fb73cc5c77fa'u64, 0xd8bc61a96accc72e'u64, 0x3f98dad0bcb1c8f3'u64,
    0xb179513c44fe1f0a'u64, 0x413b884be5b9955f'u64, 0x4b682d94916239a1'u64,
    0xe7b93a4600d77791'u64, 0x6a54f95b111a3555'u64]

var failures = 0

proc check(cond: bool, msg: string) =
  if not cond:
    stderr.writeLine("FAIL: " & msg)
    inc failures

echo "Running Cromulent Nim engine tests"

stdout.write "Testing engine matches C reference... "
var e = initEngine(0x0123456789ABCDEF'u64)
for i in 0 ..< engineRef.len:
  check(e.next == engineRef[i], "engine output " & $i)
echo "OK"

stdout.write "Testing strong engine matches C reference... "
var s = initStrongEngine(0x0123456789ABCDEF'u64)
for i in 0 ..< strongRef.len:
  check(s.next == strongRef[i], "strong output " & $i)
echo "OK"

stdout.write "Testing nextFloat range... "
var d = initEngine(42'u64)
check(abs(d.nextFloat - 0.42990649088115307) < 1e-15, "first double")
for _ in 0 ..< 10000:
  let v = d.nextFloat
  check(v >= 0.0 and v < 1.0, "double in range")
echo "OK"

stdout.write "Testing bounded... "
var b = initEngine(99'u64)
check(b.bounded(0'u64) == 0'u64, "bounded(0)")
for _ in 0 ..< 10000:
  check(b.bounded(7'u64) < 7'u64, "bounded(7) < 7")
echo "OK"

stdout.write "Testing skip equivalence... "
var a1 = initEngine(555'u64)
var a2 = initEngine(555'u64)
a1.skip(50'u64)
for _ in 0 ..< 50:
  discard a2.next
for _ in 0 ..< 100:
  check(a1.next == a2.next, "skip(n) == n calls")
echo "OK"

if failures == 0:
  echo "All Nim engine tests passed successfully!"
  quit(0)
else:
  echo $failures & " check(s) failed!"
  quit(1)
