require "luaclass"
require "luaclass.util.LuaArray"

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
print(LuaArray(D.__mro)) -- 输出 {D, B, C, A, Object}

super(d):foo() -- 输出 "B foo"
super(d, C):foo() -- 输出 "C foo"


--------

-- 演示: 冲突如何发生

class "Z" {}
class "X"(Z) {}
class "Y"(Z) {}
class "M"(X, Y) {}
class "N"(Y, X) {}

print(LuaArray(M.__mro)) --> {M, X, Y, Z, Object}
print(LuaArray(N.__mro)) --> {N, Y, X, Z, Object}

-- 将会拒绝创建 O
-- 因为M和N中X，Y的顺序是相反的
xpcall(function()
  class "O"(M, N) {}
end, print)

--[[ 输出: 
Cannot create class 'O' due to MRO conflict. (in bases: X, Y)
Current merged MRO: [O, M, N] ]]


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

print(LuaArray(J.__mro)) --> {J, E, A, F, B, C, O, Object}
print(LuaArray(K.__mro)) --> {K, F, B, G, C, D, O, Object}
print(LuaArray(L.__mro)) --> {L, G, C, H, D, A, O, Object}

xpcall(function()
  class "M"(J, K, L) {}
end, print)

--[[ 错误信息:
Cannot create class 'M' due to MRO conflict. (in bases: A, F, G)
Current merged MRO: [M, J, E, K, L] ]]