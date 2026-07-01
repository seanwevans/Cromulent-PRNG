using System.Numerics;

namespace Cromulent;

/// <summary>
/// The Cromulent PRNG — a C# port of the scalar reference generator.
///
/// Reproduces the identical 64-bit stream as the C reference implementation
/// (<c>cromulent_init</c> / <c>cromulent_next</c>) for any given seed. C#'s
/// <c>ulong</c> is a native unsigned 64-bit type, so arithmetic wraps exactly
/// like the C generator.
/// </summary>
public sealed class CromulentEngine
{
    private const ulong C3 = 0x94d049bb133111ebUL;
    private const ulong C6 = 0xd1342543de82ef95UL;

    /// <summary>Default seed, shared with the C library.</summary>
    public const ulong DefaultSeed = 0x853c49e6748fea9bUL;

    private ulong _s0;
    private ulong _s1;

    public CromulentEngine(ulong seed = DefaultSeed)
    {
        (_s0, _s1) = Seeding.Expand(seed);
    }

    /// <summary>Advances the state and returns the next 64-bit output.</summary>
    public ulong NextUInt64()
    {
        ulong s0 = _s0;
        ulong s1 = _s1;

        _s0 = s0 * C6 + s1;
        _s1 = BitOperations.RotateLeft(s1, 31) + Seeding.MixFast(s0);

        ulong result = s0 + BitOperations.RotateLeft(s1, 11);
        result ^= result >> 27;
        result *= C3;
        result ^= result >> 27;
        return result;
    }

    /// <summary>Uniform double in [0, 1) using the top 53 bits.</summary>
    public double NextDouble() => (NextUInt64() >> 11) * (1.0 / (1UL << 53));

    /// <summary>Uniform float in [0, 1) using the top 24 bits.</summary>
    public float NextFloat() => (NextUInt64() >> 40) * (1.0f / (1U << 24));

    /// <summary>
    /// Unbiased uniform integer in [0, n) via Lemire's method.
    /// Returns 0 when <paramref name="n"/> is 0.
    /// </summary>
    public ulong Bounded(ulong n)
    {
        if (n == 0)
        {
            return 0;
        }
        ulong hi = Math.BigMul(NextUInt64(), n, out ulong low);
        if (low < n)
        {
            ulong threshold = (0UL - n) % n;
            while (low < threshold)
            {
                hi = Math.BigMul(NextUInt64(), n, out low);
            }
        }
        return hi;
    }

    /// <summary>Advances the stream by <paramref name="z"/> steps.</summary>
    public void Discard(ulong z)
    {
        for (ulong i = 0; i < z; i++)
        {
            NextUInt64();
        }
    }

    public override bool Equals(object? obj) =>
        obj is CromulentEngine o && _s0 == o._s0 && _s1 == o._s1;

    public override int GetHashCode() => HashCode.Combine(_s0, _s1);
}
