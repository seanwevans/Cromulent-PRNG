using Cromulent;

// Self-contained test runner: verifies bit-for-bit parity with the C reference
// vectors and basic range/discard behavior. Exits non-zero on failure.

ulong[] engineRef =
{
    0x8b0849848b39737dUL, 0x829ecfb661e3a84dUL, 0x6cfb2afb89b5dc83UL,
    0x8ad5c0d490669f95UL, 0x8d4459e6318f2474UL, 0xa0b907b845990f61UL,
    0x2143675f2f4ff1ecUL, 0x38fff6f9c33c4f8fUL,
};

ulong[] strongRef =
{
    0xa1e9fb73cc5c77faUL, 0xd8bc61a96accc72eUL, 0x3f98dad0bcb1c8f3UL,
    0xb179513c44fe1f0aUL, 0x413b884be5b9955fUL, 0x4b682d94916239a1UL,
    0xe7b93a4600d77791UL, 0x6a54f95b111a3555UL,
};

int failures = 0;
void Check(bool cond, string msg)
{
    if (!cond) { Console.Error.WriteLine($"FAIL: {msg}"); failures++; }
}

Console.WriteLine("Running Cromulent C# engine tests");

Console.Write("Testing engine matches C reference... ");
var e = new CromulentEngine(0x0123456789ABCDEFUL);
for (int i = 0; i < engineRef.Length; i++)
{
    Check(e.NextUInt64() == engineRef[i], $"engine output {i}");
}
Console.WriteLine("OK");

Console.Write("Testing strong engine matches C reference... ");
var s = new StrongEngine(0x0123456789ABCDEFUL);
for (int i = 0; i < strongRef.Length; i++)
{
    Check(s.NextUInt64() == strongRef[i], $"strong output {i}");
}
Console.WriteLine("OK");

Console.Write("Testing NextDouble range... ");
var d = new CromulentEngine(42);
Check(Math.Abs(d.NextDouble() - 0.42990649088115307) < 1e-15, "first double");
for (int i = 0; i < 10000; i++)
{
    double v = d.NextDouble();
    Check(v >= 0.0 && v < 1.0, "double in range");
}
Console.WriteLine("OK");

Console.Write("Testing Bounded... ");
var b = new CromulentEngine(99);
Check(b.Bounded(0) == 0, "Bounded(0)");
for (int i = 0; i < 10000; i++)
{
    Check(b.Bounded(7) < 7, "Bounded(7) < 7");
}
Console.WriteLine("OK");

Console.Write("Testing Discard equivalence... ");
var a1 = new CromulentEngine(555);
var a2 = new CromulentEngine(555);
a1.Discard(50);
for (int i = 0; i < 50; i++) a2.NextUInt64();
Check(a1.Equals(a2), "Discard(n) == n calls");
Console.WriteLine("OK");

if (failures == 0)
{
    Console.WriteLine("All C# engine tests passed successfully!");
    return 0;
}
Console.WriteLine($"{failures} check(s) failed!");
return 1;
