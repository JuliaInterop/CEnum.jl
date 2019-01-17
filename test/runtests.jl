using CEnum
using Test

@cenum(Fruit, apple=1, orange=2, kiwi=2)
@test orange == kiwi
