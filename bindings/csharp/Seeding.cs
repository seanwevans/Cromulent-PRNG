namespace Cromulent;

/// <summary>Shared helpers for the Cromulent engines.</summary>
internal static class Seeding
{
    private const ulong C1 = 0x9e3779b97f4a7c15UL;
    private const ulong C2 = 0xbf58476d1ce4e5b9UL;
    private const ulong C3 = 0x94d049bb133111ebUL;
    private const ulong MH3 = 0xd6e8feb86659fd93UL;

    public static ulong MixFast(ulong x)
    {
        x ^= x >> 32;
        x *= MH3;
        x ^= x >> 32;
        return x;
    }

    /// <summary>SplitMix64-style seed expansion, matching cromulent_init.</summary>
    public static (ulong, ulong) Expand(ulong seed)
    {
        ulong z = seed;
        ulong[] outv = new ulong[2];
        for (int i = 0; i < 2; i++)
        {
            z += C1;
            z = (z ^ (z >> 30)) * C2;
            z = (z ^ (z >> 27)) * C3;
            outv[i] = z ^ (z >> 31);
        }
        return (outv[0], outv[1]);
    }
}

/// <summary>
/// The heavier "strong" Cromulent variant. Mirrors cromulent_strong_init /
/// cromulent_strong_next.
/// </summary>
public sealed class StrongEngine
{
    private const ulong C1 = 0x9e3779b97f4a7c15UL;
    private const ulong C2 = 0xbf58476d1ce4e5b9UL;

    public const ulong DefaultSeed = 0x853c49e6748fea9bUL;

    private ulong _a;
    private ulong _b;

    public StrongEngine(ulong seed = DefaultSeed)
    {
        (_a, _b) = Seeding.Expand(seed);
    }

    public ulong NextUInt64()
    {
        ulong a = _a;
        ulong b = _b;

        b += System.Numerics.BitOperations.RotateLeft(a, 13);
        a = System.Numerics.BitOperations.RotateLeft(a, 29) * C1 + b;

        b = System.Numerics.BitOperations.RotateLeft(b, 17) ^ a;
        a += System.Numerics.BitOperations.RotateLeft(b * C2, 31);

        b += System.Numerics.BitOperations.RotateLeft(a, 23);
        a = System.Numerics.BitOperations.RotateLeft(a ^ b, 52);

        ulong output = a + System.Numerics.BitOperations.RotateLeft(b, 41);

        _a = a + C1;
        _b = b ^ (a >> 17);

        return Seeding.MixFast(output);
    }

    public void Discard(ulong z)
    {
        for (ulong i = 0; i < z; i++)
        {
            NextUInt64();
        }
    }

    public override bool Equals(object? obj) =>
        obj is StrongEngine o && _a == o._a && _b == o._b;

    public override int GetHashCode() => HashCode.Combine(_a, _b);
}
