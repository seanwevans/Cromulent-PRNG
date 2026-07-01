# Cromulent PRNG — C#

A dependency-free C# port of the scalar Cromulent generator. `CromulentEngine`
reproduces the C reference stream (`cromulent_init` / `cromulent_next`)
bit-for-bit; `StrongEngine` mirrors the heavier `cromulent_strong` variant.
Uses the native `ulong` type, `BitOperations.RotateLeft`, and `Math.BigMul`
for the unbiased `Bounded` (Lemire's method).

```csharp
using Cromulent;

var rng = new CromulentEngine(0x0123456789ABCDEFUL);
ulong x = rng.NextUInt64();
double d = rng.NextDouble();   // [0, 1)
ulong r = rng.Bounded(6);      // unbiased [0, 6)
```

## Test

The project is a console app whose `Main` runs the self-test:

```bash
dotnet run -c Release
```
