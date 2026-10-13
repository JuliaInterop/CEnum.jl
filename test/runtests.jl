using CEnum
using Test

# types have to be defined at top level
@cenum(ZeroOne, zero, one)
@cenum(Fruit, apple=1, orange=2, kiwi=2)
@cenum(Boolean::Bool, alternativefact, fact)
@cenum(Day, Mon=1, Tue, Wed=3, suiyoubi=3, Fri=5, Sat)
@cenum var"##SHIFT_TEST_SIGNED#1"::Int64 begin
    SHIFT_TEST_N1000 = -1000
end
@cenum var"##SHIFT_TEST_UNSIGNED#1"::UInt64 begin
    SHIFT_TEST_123 = 0x123
    SHIFT_TEST_10 = 0x10
end
"A documented enum."
@cenum Documented doc_a

# macro errors are wrapped in a LoadError before Julia 1.7
function expand(ex)
    try
        macroexpand(@__MODULE__, ex)
    catch err
        throw(err isa LoadError ? err.error : err)
    end
end

@testset "CEnum" begin

@testset "values" begin
    @test zero == 0
    @test one == 1
    @test orange == kiwi
    @test alternativefact == false
    @test Mon == 1
    @test Tue == 2
    @test Wed == 3 == suiyoubi
    @test Fri == 5
    @test Sat == 6
    @test Fruit <: CEnum.Cenum{Int32}
    @test Boolean <: CEnum.Cenum{Bool}
    @test sizeof(Boolean) == 1
    @test Fruit(2) === orange === kiwi
    @test Fruit(0x02) === orange
    @test Fruit(apple) === apple
end

@testset "operators" begin
    @test apple | orange == 3
    @test apple & orange == 0
    @test apple + 1 == 2
    @test kiwi - 1 == 1
    @test apple * 2 == 2
    @test kiwi ÷ 2 == 1
    @test -kiwi == -2
    @test apple * orange == 2
    @test kiwi ÷ kiwi == 1
    @test kiwi ⊻ kiwi == 0
    @test ~orange == -3
    @test_nowarn print(devnull, Fruit(apple | orange))

    # issue #11
    @test 0 - one == -1

    # These tests are derived from https://en.cppreference.com/w/c/language/operator_arithmetic section "Shift operators"
    # Here we test to ensure our promotion behavior matches that of C
    @test SHIFT_TEST_123 << 1 == 0x246
    @test SHIFT_TEST_123 << 63 == 0x8000000000000000
    @test SHIFT_TEST_10 << 10 == 0x4000
    @test SHIFT_TEST_N1000 >> 1 == -500
    @test typeof(apple << Int64(1)) == Int32
    @test SHIFT_TEST_10 >> -1 == 0x20

    # mixed signedness follows Base integer promotion
    @test SHIFT_TEST_10 != -1
    @test SHIFT_TEST_10 != SHIFT_TEST_N1000
    @test SHIFT_TEST_10 + (-1) == 0x0f
    @test SHIFT_TEST_10 * SHIFT_TEST_N1000 === UInt64(0x10) * -1000

    @test apple < orange
    @test apple < 2 && 0 < apple
    @test apple < SHIFT_TEST_10
    @test hash(apple) == hash(1)
    @test apple in Set([1])
    @test !(orange < kiwi)
    @test sort([orange, apple]) == [apple, orange]
    @test ([apple, orange] .== apple) == [true, false]
end

@testset "conversion and IO" begin
    @test Integer(apple) === Int32(1)
    @test Int(orange) === 2
    @test UInt8(orange) === 0x02
    @test convert(Int, orange) === 2
    @test Base.cconvert(Cint, orange) === Cint(2)
    @test_throws InexactError Fruit(typemax(Int64))

    io = IOBuffer()
    @test write(io, orange) == 4
    write(io, Int32(7))
    seekstart(io)
    @test read(io, Fruit) === orange
    @test Integer(read(io, Fruit)) == 7
end

@testset "reflection" begin
    @test instances(Fruit) === (apple, orange, kiwi)
    @test typemin(Day) === Mon
    @test typemax(Day) === Sat
    @test Symbol(apple) === :apple
    @test Symbol(kiwi) === :orange # first name wins
    @test Symbol(Fruit(7)) === :UnknownMember
    @test haskey(Docs.meta(@__MODULE__), Docs.Binding(@__MODULE__, :Documented))
end

@testset "show" begin
    @test string(apple) == "apple"
    @test sprint(show, apple; context = :module => @__MODULE__) == "apple"
    @test sprint(show, apple; context = :module => nothing) == "$(@__MODULE__).apple"
    @test sprint(show, apple; context = :compact => true) == "apple"
    @test sprint(show, MIME"text/plain"(), apple) == "apple::Fruit = 1"
    @test sprint(show, MIME"text/plain"(), Fruit(7)) == "Fruit(7)"
    @test sprint(show, Fruit(7); context = :module => @__MODULE__) == "Fruit(7)"
    @test sprint(show, MIME"text/plain"(), Fruit) == "Cenum Fruit:\napple = 1\norange = 2\nkiwi = 2"
    # issue #25: non-concrete Cenum types
    @test sprint(show, MIME"text/plain"(), CEnum.Cenum) == sprint(show, CEnum.Cenum)
end

@testset "macro parsing" begin
    @test CEnum.parse_cenum(@__MODULE__, :Foo, (:a, :(b = 5), :c, :(d = 5))) ==
          (:Foo, Int32, [(:a, 0), (:b, 5), (:c, 6), (:d, 5)])
    @test CEnum.parse_cenum(@__MODULE__, :(Foo::UInt8), (:(begin a = 0x10; b end),)) ==
          (:Foo, UInt8, [(:a, 0x10), (:b, 0x11)])
    # issue #27: without a base type, pick the first that holds all values
    @test CEnum.parse_cenum(@__MODULE__, :Foo, (:(a = typemax(Int32)), :b))[2] == UInt32
    @test CEnum.parse_cenum(@__MODULE__, :Foo, (:(a = -1), :(b = 0x80000000)))[2] == Int64
    @test CEnum.parse_cenum(@__MODULE__, :Foo, (:(a = typemax(UInt64)),))[2] == UInt64
    @test_throws ArgumentError CEnum.parse_cenum(@__MODULE__, :Foo, (:(a = -1), :(b = typemax(UInt64))))
end

@testset "macro errors" begin
    @test_throws ArgumentError expand(:(@cenum Foo))
    @test_throws ArgumentError expand(:(@cenum Foo::Float64 a))
    @test_throws ArgumentError expand(:(@cenum Foo::Integer a))
    @test_throws ArgumentError expand(:(@cenum 1 a))
    @test_throws ArgumentError expand(:(@cenum Foo::UInt8 a=255 b))
    @test_throws ArgumentError expand(:(@cenum Foo::Bool a b c))
    @test_throws ArgumentError expand(:(@cenum Foo a=1.5))
    @test_throws ArgumentError expand(:(@cenum Foo a+1))
    @test_throws ArgumentError expand(:(@cenum Foo $(Symbol("a b"))))
    @test_throws ArgumentError expand(:(@cenum Foo a a))
    @test_throws InexactError expand(:(@cenum Foo::UInt8 a=256))
end

@testset "ambiguities" begin
    ambs = detect_ambiguities(CEnum, Base, @__MODULE__)
    @test !any(ms -> any(m -> m.module in (CEnum, @__MODULE__), ms), ambs)
end

end
