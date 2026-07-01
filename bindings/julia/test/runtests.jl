# Self-contained test for the Julia Cromulent port. Verifies bit-for-bit parity
# with the C reference vectors and basic range/discard behavior.
# Run with: julia test/runtests.jl  (from bindings/julia)

include("../src/Cromulent.jl")

using .Cromulent
using Test

const ENGINE_REF = UInt64[
    0x8b0849848b39737d, 0x829ecfb661e3a84d, 0x6cfb2afb89b5dc83,
    0x8ad5c0d490669f95, 0x8d4459e6318f2474, 0xa0b907b845990f61,
    0x2143675f2f4ff1ec, 0x38fff6f9c33c4f8f,
]

const STRONG_REF = UInt64[
    0xa1e9fb73cc5c77fa, 0xd8bc61a96accc72e, 0x3f98dad0bcb1c8f3,
    0xb179513c44fe1f0a, 0x413b884be5b9955f, 0x4b682d94916239a1,
    0xe7b93a4600d77791, 0x6a54f95b111a3555,
]

@testset "Cromulent" begin
    @testset "engine matches C reference" begin
        e = Engine(0x0123456789ABCDEF)
        for want in ENGINE_REF
            @test next_u64!(e) == want
        end
    end

    @testset "strong engine matches C reference" begin
        s = StrongEngine(0x0123456789ABCDEF)
        for want in STRONG_REF
            @test next_u64!(s) == want
        end
    end

    @testset "next_double in range" begin
        d = Engine(UInt64(42))
        @test abs(next_double!(d) - 0.42990649088115307) < 1e-15
        for _ in 1:10000
            v = next_double!(d)
            @test 0.0 <= v < 1.0
        end
    end

    @testset "bounded in range" begin
        b = Engine(UInt64(99))
        @test bounded!(b, UInt64(0)) == 0
        for _ in 1:10000
            @test bounded!(b, UInt64(7)) < 7
        end
    end

    @testset "discard equivalence" begin
        a1 = Engine(UInt64(555))
        a2 = Engine(UInt64(555))
        discard!(a1, 50)
        for _ in 1:50
            next_u64!(a2)
        end
        @test a1.s0 == a2.s0 && a1.s1 == a2.s1
    end
end
