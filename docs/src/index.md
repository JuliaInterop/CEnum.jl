# CEnum.jl

CEnum.jl provides [`@cenum`](@ref), an enum type for Julia that behaves like an
`enum` in C. It is meant for wrapping C libraries, and is what
[Clang.jl](https://github.com/JuliaInterop/Clang.jl) emits for the enums it
finds in C headers.

`Base.@enum` is stricter than C: every name needs its own value, and a variable
of the enum type can only hold one of the named values. C code relies on
neither being true, so translated headers often cannot use it:

```julia-repl
julia> @enum Foo a = 1 b = 2 c = 1
ERROR: LoadError: ArgumentError: values for Enum Foo are not unique
```

With `@cenum` the same definition works:

```jldoctest
julia> using CEnum

julia> @cenum Bar d = 1 e = 2 f = 1

julia> d == f
true
```

## Installation

```julia
julia> import Pkg; Pkg.add("CEnum")
```

CEnum.jl has no dependencies and supports Julia 1.6 and later.

## Differences from `Base.@enum`

A type defined with `@cenum`

* allows several names for the same value;
* can hold any value of its base type, not only the named ones, so results of
  bitwise operations and values returned by C code are always representable;
* compares equal to integers and to members of other `@cenum` types that have
  the same value, and hashes like the integer;
* supports integer arithmetic and bitwise operators, which return plain
  integers.

See the [Guide](@ref) for each of these in turn.
