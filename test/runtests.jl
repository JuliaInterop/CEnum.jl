using CEnum
using Test

@cenum(Fruit, apple=1, orange=2, kiwi=2)
@test orange == kiwi
@test apple | orange == 3
@test apple & orange == 0
@test apple + 1 == 2
@test kiwi - 1 == 1

@cenum(Boolean{Bool}, alternativefact, fact)
@test alternativefact == false
