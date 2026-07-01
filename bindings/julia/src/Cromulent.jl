"""
The Cromulent PRNG -- a Julia port of the scalar reference generator.

`Engine` reproduces the identical 64-bit stream as the C reference
implementation (`cromulent_init` / `cromulent_next`) for any given seed;
`StrongEngine` mirrors the heavier `cromulent_strong` variant. Julia's `UInt64`
arithmetic wraps at 2^64, matching the C generator.
"""
module Cromulent

export Engine, StrongEngine, next_u64!, next_double!, bounded!, discard!, default_seed

const C1 = 0x9e3779b97f4a7c15
const C2 = 0xbf58476d1ce4e5b9
const C3 = 0x94d049bb133111eb
const C6 = 0xd1342543de82ef95
const MH3 = 0xd6e8feb86659fd93

"Default seed, shared with the C library."
const default_seed = 0x853c49e6748fea9b

@inline function mix_fast(x::UInt64)
    x ⊻= x >> 32
    x *= MH3
    x ⊻= x >> 32
    return x
end

"SplitMix64-style seed expansion, matching cromulent_init."
function seed_expand(seed::UInt64)
    z = seed
    out = Vector{UInt64}(undef, 2)
    for i in 1:2
        z += C1
        z = (z ⊻ (z >> 30)) * C2
        z = (z ⊻ (z >> 27)) * C3
        out[i] = z ⊻ (z >> 31)
    end
    return (out[1], out[2])
end

"The primary Cromulent engine."
mutable struct Engine
    s0::UInt64
    s1::UInt64
end

Engine(seed::UInt64 = default_seed) = Engine(seed_expand(seed)...)

"Advance the state and return the next 64-bit output."
function next_u64!(e::Engine)
    s0 = e.s0
    s1 = e.s1

    e.s0 = s0 * C6 + s1
    e.s1 = bitrotate(s1, 31) + mix_fast(s0)

    r = s0 + bitrotate(s1, 11)
    r ⊻= r >> 27
    r *= C3
    r ⊻= r >> 27
    return r
end

"Uniform Float64 in [0, 1) using the top 53 bits."
next_double!(e::Engine) = Float64(next_u64!(e) >> 11) * (1.0 / 9007199254740992.0)

"Unbiased uniform integer in [0, n) via Lemire's method. Returns 0 when n == 0."
function bounded!(e::Engine, n::UInt64)
    n == 0 && return UInt64(0)
    m = widemul(next_u64!(e), n)
    low = m % UInt64
    hi = (m >> 64) % UInt64
    if low < n
        threshold = (-n) % n
        while low < threshold
            m = widemul(next_u64!(e), n)
            low = m % UInt64
            hi = (m >> 64) % UInt64
        end
    end
    return hi
end

"Advance the stream by z steps, discarding the output."
function discard!(e::Engine, z::Integer)
    for _ in 1:z
        next_u64!(e)
    end
end

"The heavier \"strong\" Cromulent variant."
mutable struct StrongEngine
    a::UInt64
    b::UInt64
end

StrongEngine(seed::UInt64 = default_seed) = StrongEngine(seed_expand(seed)...)

function next_u64!(e::StrongEngine)
    a = e.a
    b = e.b

    b += bitrotate(a, 13)
    a = bitrotate(a, 29) * C1 + b
    b = bitrotate(b, 17) ⊻ a
    a += bitrotate(b * C2, 31)
    b += bitrotate(a, 23)
    a = bitrotate(a ⊻ b, 52)

    output = a + bitrotate(b, 41)

    e.a = a + C1
    e.b = b ⊻ (a >> 17)

    return mix_fast(output)
end

function discard!(e::StrongEngine, z::Integer)
    for _ in 1:z
        next_u64!(e)
    end
end

end # module
