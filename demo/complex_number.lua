require "luaclass"

-- 这个文件中演示各种运算符重载
-- 就是 Lua 里面的那些元方法

-- 定义一个复数类

class "Complex" {
  -- 构造函数
  __init = function(self, real, imag)
    self.real = real or 0
    self.imag = imag or 0
  end;

  -- 加法, 允许有一个操作数是实数
  -- a: 左操作数, b: 右操作数
  __add = function(a, b)
    local typa = luaclass(a)
    local typb = luaclass(b)

    if typa == typb then
      return Complex(a.real + b.real, a.imag + b.imag)
    elseif typa == "number" then
      return Complex(a + b.real, b.imag)
    elseif typb == "number" then
      return Complex(a.real + b, a.imag)
    end

    error(("attempt to perform arithmetic on a %d value")
      :format(typa == Complex and typb or typa), 2)
  end;

  -- 相反数
  __unm = function(self)
    return Complex(-self.real, -self.imag)
  end;

  -- 减法, 定义为加上相反数
  __sub = function(a, b)
    local opst = -b
    return a + opst
  end;

  -- 乘法, 允许有一个操作数是实数
  __mul = function(a, b)
    local typa = luaclass(a)
    local typb = luaclass(b)

    if typa == typb then
      return Complex(a.real*b.real - a.imag*b.imag, a.real*b.imag + a.imag*b.real)
    elseif typa == "number" then
      return Complex(a * b.real, a * b.imag)
    elseif typb == "number" then
      return Complex(a.real * b, a.imag * b)
    end

    error(("attempt to perform arithmetic on a %d value")
      :format(typa == Complex and typb or typa), 2)
  end;

  -- 模的平方
  modulusquare = function(self)
    return self.real*self.real + self.imag*self.imag
  end;

  -- 长度算符, 定义为复数的模
  __len = function(self)
    return math.sqrt(self.real*self.real + self.imag*self.imag)
  end;

  -- 除法, 允许有一个操作数是实数
  __div = function(a, b)
    local typa = luaclass(a)
    local typb = luaclass(b)

    if typa == typb then
      local base = b:modulusquare()
      local real = a.real*b.real + a.imag*b.imag
      local imag = a.imag*b.real - a.real*b.imag
      return Complex(real / base, imag / base)
    elseif typa == "number" then
      return Complex(a) / b
    elseif typb == "number" then
      return Complex(a.real / b, a.imag / b)
    end

    error(("attempt to perform arithmetic on a %d value")
      :format(typa == Complex and typb or typa), 2)
  end;

  -- 自定义显示样式
  __tostring = function(self)
    local imag = self.imag
    if imag > 0 then
      return ("%g+%gi"):format(self.real, imag)
    elseif imag < 0 then
      return ("%g-%gi"):format(self.real, -imag)
    else
      return tostring(self.real)
    end
  end
}

local z1 = Complex(1, 2)
local z2 = Complex(3, 4)

print(z1 + z2) -- 输出: 4+6i
print(z1 - z2) -- 输出: -2-2i
print(z1 * z2) -- 输出: -5+10i
print(z1 / z2) -- 输出: 0.44+0.08i

print(#z2) -- 输出: 5.0

print(Complex(1)) -- 输出: 1
