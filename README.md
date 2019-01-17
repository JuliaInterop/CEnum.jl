# CEnum

[![Build Status](https://travis-ci.com/JuliaInterop/CEnum.jl.svg?branch=master)](https://travis-ci.com/JuliaInterop/CEnum.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/JuliaInterop/CEnum.jl?svg=true)](https://ci.appveyor.com/project/JuliaInterop/CEnum-jl)
[![Codecov](https://codecov.io/gh/JuliaInterop/CEnum.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaInterop/CEnum.jl)

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

## Credit
The original version is written by [SimonDanisch](https://github.com/SimonDanisch) in [this PR](https://github.com/JuliaInterop/Clang.jl/pull/162).
