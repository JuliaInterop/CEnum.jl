# Guide

```@meta
DocTestSetup = :(using CEnum)
```

## Defining an enum

The members are listed after the type name, either on one line or in a
`begin` block. A member without a value gets the value of the previous member
plus one, and the first member starts at zero.

```jldoctest guide
julia> @cenum Fruit apple=1 orange=2 kiwi=2

julia> @cenum Day begin
           Mon = 1
           Tue
           Wed
       end

julia> Tue
Tue::Day = 2
```

Each member becomes a constant in the module where `@cenum` is called.
A value can be any expression that evaluates to an integer when the macro is
expanded, such as `1 << 4` or a constant defined earlier in the module.

Several members may share a value. They are then the same object, which is
shown under the first of its names:

```jldoctest guide
julia> orange === kiwi
true

julia> kiwi
orange::Fruit = 2
```

## Base type

The integer type used to store the enum can be given after the name. It has to
be a primitive integer type.

```jldoctest guide
julia> @cenum Color::UInt8 red green blue=0x10

julia> sizeof(Color)
1

julia> Integer(blue)
0x10
```

Without one, the base type is `Int32`, which is what C compilers use for most
enums. If a value does not fit in an `Int32`, the first of `UInt32`, `Int64` and
`UInt64` that can hold all the values is used instead:

```jldoctest guide
julia> @cenum Mask small=20 large=5123123123

julia> typeof(Integer(large))
Int64
```

When a C header is translated, give the base type the C compiler chose, so
that the size of the enum matches in `ccall` and in struct layouts.

## Values without a name

As in C, an enum can hold any value of its base type. Converting an integer
never fails as long as it fits the base type:

```jldoctest guide
julia> Fruit(2)
orange::Fruit = 2

julia> Fruit(7)
Fruit(7)
```

This is what makes enums usable as bit flags, see below.

## Operators

Members can be compared with integers and with members of other enums. The
comparison is made on the underlying values.

```jldoctest guide
julia> apple == 1
true

julia> apple < orange
true

julia> apple in Set([1, 2])
true
```

`+`, `-`, `*`, `÷`, `&`, `|`, `xor`, `~`, `<<` and `>>` work between members and
integers. They return an integer, not an enum; wrap the result in the type to
get an enum back.

```jldoctest guide
julia> @cenum Flags::UInt32 readable=1 writable=2 executable=4

julia> readable | writable
0x00000003

julia> Flags(readable | writable)
Flags(0x00000003)

julia> (Flags(0x03) & writable) != 0
true

julia> apple + 1
2
```

## Conversion and `ccall`

`Integer(x)` gives the underlying value in the base type, and any integer type
can be used as a constructor in the same way.

```jldoctest guide
julia> Integer(orange)
2

julia> UInt8(orange)
0x02
```

A `@cenum` type is a primitive type with the size of its base type, so it can
be used directly as an argument or return type in `ccall`, and as a field type
in structs that mirror C structs. An enum value can also be passed where the C
function expects the underlying integer type.

```julia
ccall((:set_color, libfoo), Cvoid, (Color,), green)
ccall((:get_color, libfoo), Color, ())
```

`read(io, T)` and `write(io, x)` read and write the underlying integer.

## Names and members

```jldoctest guide
julia> instances(Fruit)
(apple, orange, orange)

julia> Symbol(apple)
:apple

julia> string(orange)
"orange"

julia> typemin(Day), typemax(Day)
(Mon, Wed)
```

`instances` has one entry for each name, so a value with several names appears
more than once. `Symbol` and `string` give the first name of a value, and
`:UnknownMember` if it has none.

Displaying the type lists its members:

```jldoctest guide
julia> Fruit
Cenum Fruit:
apple = 1
orange = 2
kiwi = 2
```

## Dispatching on enums

All types defined with `@cenum` are subtypes of [`CEnum.Cenum`](@ref), which is
parameterized by the base type. It is not exported.

```jldoctest guide
julia> Fruit <: CEnum.Cenum{Int32}
true

julia> describe(x::CEnum.Cenum) = string(typeof(x), " with value ", Integer(x));

julia> describe(apple)
"Fruit with value 1"
```
