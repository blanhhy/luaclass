require "luaclass"
require "tablex"

-- MRO演示
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