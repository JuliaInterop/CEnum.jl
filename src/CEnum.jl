# copied from https://github.com/JuliaLang/julia/pull/30924
# modified to be in compliance with C99: http://port70.net/~nsz/c/c99/n1256.html#6.7.2.2
module CEnum

import Core.Intrinsics.bitcast
export @cenum

function namemap end
function name_value_pairs end

"""
    Cenum{T<:Integer}
The abstract supertype of all enumerated types defined with [`@cenum`](@ref).
"""
abstract type Cenum{T<:Integer} end

basetype(::Type{<:Cenum{T}}) where {T<:Integer} = T

(::Type{T})(x::Cenum{T2}) where {T<:Integer,T2<:Integer} = T(bitcast(T2, x))::T
Base.convert(::Type{T1}, x::Cenum{T2}) where {T1<:Integer,T2<:Integer} = convert(T1, T2(x))
Base.cconvert(::Type{T}, x::Cenum) where {T<:Integer} = T(x)
Base.write(io::IO, x::Cenum{T}) where {T<:Integer} = write(io, T(x))
Base.read(io::IO, ::Type{T}) where {T<:Cenum} = T(read(io, basetype(T)))

# consistent with `==`, which compares the underlying integers
Base.hash(x::Cenum, h::UInt) = hash(Integer(x), h)

Base.Symbol(x::Cenum)::Symbol = get(namemap(typeof(x)), Integer(x), :UnknownMember)

Base.print(io::IO, x::Cenum) = print(io, Symbol(x))

function Base.show(io::IO, x::Cenum)
    if !haskey(namemap(typeof(x)), Integer(x))
        # no member has this value
        show(io, typeof(x))
        print(io, "(")
        show(io, Integer(x))
        print(io, ")")
        return
    end
    sym = Symbol(x)
    if !get(io, :compact, false)::Bool
        from = get(io, :module, Main)
        def = typeof(x).name.module
        if from === nothing || !Base.isvisible(sym, def, from)
            show(io, def)
            print(io, ".")
        end
    end
    print(io, sym)
end

function Base.show(io::IO, ::MIME"text/plain", x::Cenum)
    print(io, x, "::")
    show(IOContext(io, :compact => true), typeof(x))
    print(io, " = ")
    show(io, Integer(x))
end

function Base.show(io::IO, ::MIME"text/plain", t::Type{<:Cenum})
    if !isconcretetype(t)
        # e.g. the abstract `Cenum` type itself, or a `UnionAll` such as `Cenum{T}`;
        # `show_datatype` and `name_value_pairs` only work for concrete Cenum types
        show(io, t)
        return
    end
    print(io, "Cenum ")
    Base.show_datatype(io, t)
    print(io, ":")
    for (s, i) in name_value_pairs(t)
        print(io, "\n", s, " = ")
        show(io, Integer(i))
    end
end

# give Cenum types scalar behavior in broadcasting
Base.broadcastable(x::Cenum) = Ref(x)

# binary functions defined between Cenums and between a Cenum and an Integer;
# operands are unwrapped to the base type and the result is a plain integer
const BINARY_OPS = (:+, :-, :*, :div, :&, :|, :xor, :(==), :isless, :<<, :>>)

# base types tried in turn when `@cenum` is not given one
const DEFAULT_BASETYPES = (Int32, UInt32, Int64, UInt64)

# These are defined once on `Cenum` rather than for each type. Some of them
# (the bitwise ones with an `Integer` argument) invalidate compiled code in
# Base, but defining them per type only moves the same invalidations to the
# first `@cenum`, and costs load and precompile time for every type.
for op in BINARY_OPS
    @eval begin
        Base.$op(a::Cenum{T}, b::Cenum{S}) where {T<:Integer,S<:Integer} = Base.$op(T(a), S(b))
        Base.$op(a::Cenum{T}, b::Integer) where {T<:Integer} = Base.$op(T(a), b)
        Base.$op(a::Integer, b::Cenum{T}) where {T<:Integer} = Base.$op(a, T(b))
    end
end

Base.:~(a::Cenum{T}) where {T<:Integer} = ~T(a)
Base.:-(a::Cenum{T}) where {T<:Integer} = -T(a)

"""
    @cenum EnumName[::BaseType] value1[=x] value2[=y]

Create a [`Cenum`](@ref) subtype with name `EnumName` and members `value1`,
`value2`, and so on. It works like `Base.@enum`, but follows the semantics of
C enums:

* several members may share the same value;
* `EnumName(x)` accepts any `x` representable in `BaseType`, not only the values
  of the named members;
* members can be combined with integers and with each other using `==`, `<`,
  `+`, `-`, `*`, `÷`, `&`, `|`, `xor`, `~`, `<<` and `>>`. Arithmetic gives an
  integer of the base type (promoted as usual for integers), not an `EnumName`.

`BaseType` must be a primitive integer type. It defaults to `Int32`, or to the
first of `UInt32`, `Int64` and `UInt64` that can hold all values if `Int32`
cannot, which is the choice C compilers make. A member
without an explicit value gets the value of the previous member plus one,
starting from zero. Members can also be listed in a `begin` block.

# Examples
```julia
julia> @cenum Fruit apple=1 orange=2 kiwi=2

julia> orange == kiwi
true

julia> apple | orange
3

julia> @cenum Color::UInt8 begin
           red
           green
           blue = 0x10
       end

julia> Integer(green)
0x01
```
"""
macro cenum(T, syms...)
    return emit_cenum(parse_cenum(__module__, T, syms)...)
end

# Parse the arguments of `@cenum` into the type name, the base type and the
# `(name, value)` members in order of definition. Base type and value
# expressions are evaluated in `mod`.
function parse_cenum(mod::Module, T, syms)
    if isempty(syms)
        throw(ArgumentError("no arguments given for Cenum $T"))
    end
    basetype = nothing # chosen from the values unless given
    typename = T
    if isa(T, Expr) && T.head === :(::) && length(T.args) == 2 && isa(T.args[1], Symbol)
        typename = T.args[1]
        basetype = Core.eval(mod, T.args[2])
        if !isa(basetype, DataType) || !(basetype <: Integer) || !isbitstype(basetype)
            throw(ArgumentError("invalid base type for Cenum $typename, $T=::$basetype; base type must be an integer primitive type"))
        end
    elseif !isa(T, Symbol)
        throw(ArgumentError("invalid type expression for Cenum $T"))
    end
    seen = Set{Symbol}()
    raw = Tuple{Symbol,Union{Nothing,Integer}}[] # `nothing`: previous value plus one

    if length(syms) == 1 && syms[1] isa Expr && syms[1].head === :block
        syms = syms[1].args
    end
    for s in syms
        s isa LineNumberNode && continue
        v = nothing
        if isa(s, Expr) &&
           (s.head === :(=) || s.head === :kw) &&
           length(s.args) == 2 && isa(s.args[1], Symbol)
            v = Core.eval(mod, s.args[2]) # allow exprs, e.g. uint128"1"
            if !isa(v, Integer)
                throw(ArgumentError("invalid value for Cenum $typename, $s; values must be integers"))
            end
            s = s.args[1]
        elseif !isa(s, Symbol)
            throw(ArgumentError(string("invalid argument for Cenum ", typename, ": ", s)))
        end
        if !Base.isidentifier(s)
            throw(ArgumentError("invalid name for Cenum $typename; \"$s\" is not a valid identifier"))
        end
        if s in seen
            throw(ArgumentError("name \"$s\" in Cenum $typename is not unique"))
        end
        push!(seen, s)
        push!(raw, (s, v))
    end
    if basetype === nothing
        for B in DEFAULT_BASETYPES
            members = assign_values(B, raw)
            members isa Vector && return typename, B, members
        end
        throw(ArgumentError("values of Cenum $typename do not fit in any of $(join(DEFAULT_BASETYPES, ", ")); give a base type"))
    end
    members = assign_values(basetype, raw)
    if !isa(members, Vector)
        s, v = members
        v === nothing && throw(ArgumentError("overflow in value \"$s\" of Cenum $typename"))
        throw(InexactError(:convert, basetype, v))
    end
    return typename, basetype, members
end

# Give the members in `raw` values of type `B`. Returns the `(name, value)`
# vector, or the first entry of `raw` whose value does not fit in `B`.
function assign_values(::Type{B}, raw) where {B<:Integer}
    members = Tuple{Symbol,B}[]
    i = zero(B)      # value of the next member without an explicit one
    overflow = false # that value would be past typemax(B)
    for (s, v) in raw
        if v === nothing
            overflow && return (s, v)
        else
            typemin(B) <= v <= typemax(B) || return (s, v)
            i = convert(B, v)
        end
        push!(members, (s, i))
        overflow = i == typemax(B)
        overflow || (i = convert(B, i + oneunit(B)))
    end
    return members
end

# Build the definitions for the output of `parse_cenum`.
function emit_cenum(typename::Symbol, basetype::DataType, members::Vector)
    T = esc(typename)
    # the first name defined for a value is the one it prints as
    names = Dict{basetype,Symbol}()
    for (sym, i) in members
        get!(names, i, sym)
    end
    lo, hi = isempty(members) ? (0, 0) : extrema(last, members)
    blk = quote
        # enum definition
        Base.@__doc__(primitive type $T <: Cenum{$basetype} $(sizeof(basetype) * 8) end)
        function $T(x::Integer)
            return bitcast($T, convert($basetype, x))
        end
        $T(x::$T) = x
        CEnum.namemap(::Type{$T}) = $names
        CEnum.name_value_pairs(::Type{$T}) = $members
        Base.typemin(x::Type{$T}) = $T($lo)
        Base.typemax(x::Type{$T}) = $T($hi)
        let insts = (Any[ $T(v[2]) for v in $members ]...,)
            Base.instances(::Type{$T}) = insts
        end
    end
    for (sym, i) in members
        push!(blk.args, :(const $(esc(sym)) = $T($i)))
    end
    push!(blk.args, :nothing)
    blk.head = :toplevel
    return blk
end

end # module
