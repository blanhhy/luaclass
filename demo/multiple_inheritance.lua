require "luaclass"
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
-- 将会拒绝创建class O
-- 因为M和N中X，Y的顺序是相反的