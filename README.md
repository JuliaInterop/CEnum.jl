# CEnum

[![Build Status](https://github.com/JuliaInterop/CEnum.jl/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/JuliaInterop/CEnum.jl/actions/workflows/ci.yml?query=branch%3Amaster)
[![Codecov](https://codecov.io/gh/JuliaInterop/CEnum.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaInterop/CEnum.jl)
[![PkgEval](https://juliaci.github.io/NanosoldierReports/pkgeval_badges/C/CEnum.svg)](https://juliaci.github.io/NanosoldierReports/pkgeval_badges/C/CEnum.html)
[![version](https://img.shields.io/github/v/release/JuliaInterop/CEnum.jl)](https://github.com/JuliaInterop/CEnum.jl/releases/latest)
[![Downloads](https://img.shields.io/badge/dynamic/json?url=http%3A%2F%2Fjuliapkgstats.com%2Fapi%2Fv1%2Fmonthly_downloads%2FCEnum&query=total_requests&suffix=%2Fmonth&label=Downloads)](https://juliapkgstats.com/pkg/CEnum)

This package provides a C-compatible enum for Julia.

```julia
julia> @enum Foo a = 1 b = 2 c = 1
ERROR: LoadError: ArgumentError: values for Enum Foo are not unique
Stacktrace:
 [1] @enum(::LineNumberNode, ::Module, ::Any, ::Vararg{Any,N} where N) at ./Enums.jl:128
in expression starting at REPL[12]:1

julia> using CEnum

julia> @cenum(Bar, d = 1, e = 2, f = 1)

julia> d == f
true
```

## Usage

```julia
@cenum Fruit apple=1 orange=2 kiwi=2      # base type defaults to Int32
@cenum Color::UInt8 red green blue=0x10   # explicit base type; red == 0, green == 1
@cenum Day begin                          # block form
    Mon = 1
    Tue
end
```

Compared to `Base.@enum`, a type defined with `@cenum`

* allows several names for the same value (`orange == kiwi`);
* can hold any value of its base type, as in C: `Fruit(7)` is valid and prints as `UnknownMember`;
* supports `==`, `+`, `-`, `*`, `÷`, `&`, `|`, `xor`, `~`, `<<` and `>>` with integers and other `@cenum` values.
  These return plain integers, so wrap the result to get an enum back: `Fruit(apple | orange)`.

`Integer(x)` (or any integer type) gives the underlying value, `instances(T)` lists the members and
`Symbol(x)` gives the first name defined for the value. All types defined with `@cenum` are subtypes of `CEnum.Cenum{BaseType}`.

## Credit
The original version is written by [SimonDanisch](https://github.com/SimonDanisch) in [this PR](https://github.com/JuliaInterop/Clang.jl/pull/162).
