if not require "luaclass" then
  dofile "../luaclass/init.lua"
end
require "tablex"

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
table.print(D.__mro) -- 输出 { D, B, C, A }
super(d):foo() -- 输出 "B foo"


--------


class "Z" {}
class "X"(Z) {}
class "Y"(Z) {}
class "M"(X, Y) {}
class "N"(Y, X) {}

table.print(M.__mro) --> { M, X, Y, Z }
table.print(N.__mro) --> { N, Y, X, Z }

class "O"(M, N) {}
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

table.print(J.__mro) --> { J, E, F, A, B, C, O }

class "M"(J, K, L) {}
-- 错误信息：
-- Cannot create class 'M' due to MRO conflict. (in bases: D, A)
-- Processing traceback: M -> J -> K -> L -> E -> F -> G -> H -> A -> B -> C -> D ... D@12 -> A@9 (in branch 'J', level #3)
