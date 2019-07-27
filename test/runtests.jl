using CEnum
using Test

@cenum(ZeroOne, zero, one)
@test zero == 0
@test one == 1

@cenum(Fruit, apple=1, orange=2, kiwi=2)
@test orange == kiwi
@test apple | orange == 3
@test apple & orange == 0
@test apple + 1 == 2
@test kiwi - 1 == 1
@test kiwi ⊻ kiwi == 0
@test_nowarn print(Fruit(apple | orange))

@cenum(Boolean::Bool, alternativefact, fact)
@test alternativefact == false

@cenum(Day, Mon=1, Tue, Wed=3, suiyoubi=3, Fri=5, Sat)
@test Mon == 1
@test Tue == 2
@test Wed == 3 == suiyoubi
@test Fri == 5
@test Sat == 6
