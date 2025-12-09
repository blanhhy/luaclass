require "luaclass"
require "tablex"
-- tablex 是我的另一个实用的模块, 目前版本稳定无变动

-- 本文件演示多继承的具体用法, 边界情况, 以及一些错误的用法

--------

-- 演示: 解决菱形继承

class "A" {
  foo = function() print("A foo") end;
}

class "B"(A) {
  foo = function() print("B foo") end;
}

class "C"(A) {
  foo = function() print("C foo") end;
}

class "D"(B, C) {
  foo = function() print("D foo") end;
}


local d = D()
d:foo() -- 输出 "D foo"
table.print(D.__mro) -- 输出 { D, B, C, A, Object}
super(d):foo() -- 输出 "B foo"


--------

-- 演示: 冲突如何发生

class "Z" {}
class "X"(Z) {}
class "Y"(Z) {}
class "M"(X, Y) {}
class "N"(Y, X) {}

table.print(M.__mro) --> { M, X, Y, Z, Object }
table.print(N.__mro) --> { N, Y, X, Z, Object }

-- class "O"(M, N) {}
-- 将会拒绝创建 O
-- 因为M和N中X，Y的顺序是相反的


--------

-- 复杂的例子

class "O" {}

class "A"(O) {}
class "B"(O) {}
class "C"(O) {}
class "D"(O) {}

class "E"(A, B) {}
class "F"(B, C) {}
class "G"(C, D) {}
class "H"(D, A) {}

class "J"(E, F) {}
class "K"(F, G) {}
class "L"(G, H) {}

table.print(J.__mro) --> { J, E, F, A, B, C, O, Object }
table.print(K.__mro) --> { K, F, G, B, C, D, O, Object }
table.print(L.__mro) --> { L, G, H, C, D, A, O, Object }

xpcall(function()
  class "M"(J, K, L) {}
end, print)
--[[
错误信息:
Cannot create class 'M' due to MRO conflict. (in bases: D, A)
Processing traceback:
    [ M -> J -> K -> L -> E -> F -> G -> H -> A@9 -> B -> C -> D@12 -> D@13 -> A@14 ]
    interrupt at MRO of superclass 'L', level #3
]]
