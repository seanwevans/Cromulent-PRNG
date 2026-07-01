namespace Cromulent

open System.Numerics

/// The Cromulent PRNG — an F# port of the scalar reference generator.
///
/// The engines reproduce the identical 64-bit stream as the C reference
/// implementation (cromulent_init / cromulent_next) for any given seed. F#'s
/// uint64 is a native unsigned 64-bit type, so arithmetic wraps exactly like
/// the C generator and >>> is a logical shift.
module internal Internal =
    let C1 = 0x9e3779b97f4a7c15UL
    let C2 = 0xbf58476d1ce4e5b9UL
    let C3 = 0x94d049bb133111ebUL
    let C6 = 0xd1342543de82ef95UL
    let MH3 = 0xd6e8feb86659fd93UL

    let inline mixFast (x0: uint64) : uint64 =
        let mutable x = x0
        x <- x ^^^ (x >>> 32)
        x <- x * MH3
        x <- x ^^^ (x >>> 32)
        x

    /// SplitMix64-style seed expansion, matching cromulent_init.
    let seedExpand (seed: uint64) : uint64 * uint64 =
        let mutable z = seed
        let step () =
            z <- z + C1
            z <- (z ^^^ (z >>> 30)) * C2
            z <- (z ^^^ (z >>> 27)) * C3
            z ^^^ (z >>> 31)
        let v0 = step ()
        let v1 = step ()
        (v0, v1)

open Internal

/// Default seed, shared with the C library.
[<AutoOpen>]
module Constants =
    let DefaultSeed = 0x853c49e6748fea9bUL

/// The primary Cromulent engine.
type CromulentEngine(seed: uint64) =
    let s = seedExpand seed
    let mutable s0 = fst s
    let mutable s1 = snd s

    new() = CromulentEngine(DefaultSeed)

    /// Advance the state and return the next 64-bit output.
    member _.NextUInt64() : uint64 =
        let a = s0
        let b = s1
        s0 <- a * C6 + b
        s1 <- BitOperations.RotateLeft(b, 31) + mixFast a
        let mutable result = a + BitOperations.RotateLeft(b, 11)
        result <- result ^^^ (result >>> 27)
        result <- result * C3
        result <- result ^^^ (result >>> 27)
        result

    /// Uniform double in [0, 1) using the top 53 bits.
    member this.NextDouble() : float =
        float (this.NextUInt64() >>> 11) * (1.0 / float (1UL <<< 53))

    /// Unbiased uniform integer in [0, n) via Lemire's method. Returns 0 when n = 0.
    member this.Bounded(n: uint64) : uint64 =
        if n = 0UL then
            0UL
        else
            let mutable low = 0UL
            let mutable hi = System.Math.BigMul(this.NextUInt64(), n, &low)
            if low < n then
                let threshold = (0UL - n) % n
                while low < threshold do
                    hi <- System.Math.BigMul(this.NextUInt64(), n, &low)
            hi

    /// Advance the stream by z steps, discarding the output.
    member this.Discard(z: uint64) : unit =
        for _ in 1UL .. z do
            this.NextUInt64() |> ignore

    member _.State = (s0, s1)

/// The heavier "strong" Cromulent variant.
type StrongEngine(seed: uint64) =
    let s = seedExpand seed
    let mutable a = fst s
    let mutable b = snd s

    new() = StrongEngine(DefaultSeed)

    member _.NextUInt64() : uint64 =
        let mutable x = a
        let mutable y = b
        y <- y + BitOperations.RotateLeft(x, 13)
        x <- BitOperations.RotateLeft(x, 29) * C1 + y
        y <- BitOperations.RotateLeft(y, 17) ^^^ x
        x <- x + BitOperations.RotateLeft(y * C2, 31)
        y <- y + BitOperations.RotateLeft(x, 23)
        x <- BitOperations.RotateLeft(x ^^^ y, 52)
        let output = x + BitOperations.RotateLeft(y, 41)
        a <- x + C1
        b <- y ^^^ (x >>> 17)
        mixFast output

    member this.Discard(z: uint64) : unit =
        for _ in 1UL .. z do
            this.NextUInt64() |> ignore

    member _.State = (a, b)
