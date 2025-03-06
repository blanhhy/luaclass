require "luaclass"

-- 基本函数与语法演示
-- 定义一个类
class "my" {
  a = 10;
  hh = function(self, t)
    t = t or self.a
    print(self.__classname.."调用了超类方法"..t)
  end;
}

-- 用原始方式创建一个子类
-- 需要手动接收值，而不会自动加入环境变量
local your = luaclass("your", {
  a = 20,
  hh = function(self, t)
    print(self.__classname.."调用了子类方法"..t)
  end
}, my)

-- 定义一个 "my" 的子类
class "your2" (my) {
  hh = function(self, t)
    super():hh(t) -- 在类方法中调用超类方法时，可以不传递参数
    print(self.__classname.."调用了子类方法"..t)
  end
}

print(my.a)
-- 输出 10

super(your):hh()
-- 输出 your调用了超类方法20

your2:hh(7)
-- 输出 your2调用了超类方法7
-- 输出 your2调用了子类方法7


--------


-- 多次继承与实例化演示
-- 定义myFirstClass
class "myFirstClass" {
  name = "李华";
  __init = function(self, age)
    if age then
      self.age = age
     else
      self.age = 12
    end
  end;
  speak = function(self)
    print(self.name.."，"..self.age.."岁")
  end;
}

-- 继承myFirstClass类，并覆写name属性和speak方法
class "mySecondClass"( myFirstClass) {
  name = "小明";
  setRelationship = function(self)
    return "爸", 0
  end;
  speak = function(self)
    local relationship, agegap = self.setRelationship()
    print("我叫"..self.name.."，今年"..tostring(self.age+agegap).."岁")
  end;
}

-- 继承mySecondClass类，并覆写speak方法
class "myThirdClass"(mySecondClass) {
  setRelationship = function(self)
    return "爸", 20
  end;
  speak = function(self)
    local relationship, agegap = self:setRelationship()
    print("我是"..self.name.."他"..relationship.."，今年"..tostring(self.age+agegap).."岁")
  end;
}

-- 创建一些实例
local c = myThirdClass(8)
local b = mySecondClass(8)
local a = myFirstClass(16)

c:speak()
-- 输出 我是小明他爸，今年28岁

super(c):speak() -- 调用超类的speak方法
-- 输出 我叫小明，今年28岁

b:speak()
-- 输出 我叫小明，今年8岁

a:speak()
-- 输出 李华，16岁


--------


-- 自定义对象行为演示
-- 定义一个复数类
class "Complex" {
  __init = function(self, real, imag)
    self.real = real
    self.imag = imag
  end;

  -- 操作符重载
  __add = function(a, b)
    local num_type = type(b)
    if num_type == "Complex" then
      return Complex(a.real + b.real, a.imag + b.imag) -- 复数相加
     elseif num_type == "number" then
      return Complex(a.real + b, a.imag) -- 复数加实数
    end
  end;
  __sub = function(a, b)
    local num_type = type(b)
    if num_type == "Complex" then
      return Complex(a.real - b.real, a.imag - b.imag)
     elseif num_type == "number" then
      return Complex(a.real - b, a.imag)
    end
  end;
  __unm = function(self)
    return Complex(- a.real, - a.imag)
  end;
  __mul = function(a, b)
    local num_type = type(b)
    if num_type == "Complex" then
      return Complex(a.real * b.real - a.imag * b.imag, a.real * b.imag + a.imag * b.real)
     elseif num_type == "number" then
      return Complex(a.real * b, a.imag * b)
    end
  end;

  -- 自定义显示样式
  __tostring = function(self)
    local imag = self.imag
    if imag > 0 then
      return string.format("%d + %di", self.real, imag)
     elseif imag < 0 then
      return string.format("%d - %di", self.real, - imag)
     else
      return string.format("%d", self.real)
    end
  end
}

local z1 = Complex(1, 2)
local z2 = Complex(3, 4)

print(tostring(z1 + z2)) --> 4 + 6i
print(tostring(z1 * z2)) --> -5 + 10i


--------


-- 菱形继承演示
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

-- MRO演示
class. O {}

class. A(O) {}
class. B(O) {}
class. C(O) {}
class. D(O) {}

class. E(A, B) {}
class. F(B, C) {}
class. G(C, D) {}
class. H(D, A) {}

class. J(E, F) {}
class. K(F, G) {}
class. L(G, H) {}

table.print(J.__mro) --> { J, E, F, A, B, C, O }

class. M(J, K, L) {}
-- 错误信息：
-- Cannot create class 'M' due to MRO conflict. (in bases: D, A)
-- Processing traceback: M -> J -> K -> L -> E -> F -> G -> H -> A -> B -> C -> D ... D@12 -> A@9 (in branch 'J', level #3)



class. X(luaclass) {}
class. Y(luaclass) {}
class. A(X, Y) {}
class. B(Y, X) {}

table.print(A.__mro) --> { A, X, Y, luaclass }
table.print(B.__mro) --> { B, Y, X, luaclass }

class. C(A, B) {}
-- 将会拒绝创建class C，因为A和B中X，Y的顺序是相反的