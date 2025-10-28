if not require "luaclass" then
  dofile "../luaclass/init.lua"
end

-- 定义一个复数类
class "Complex" {
  __init = function(self, real, imag)
    self.real = real
    self.imag = imag
  end;

  -- 运算符重载
  __add = function(a, b)
    local num_type = luaclass(b)
    if num_type == Complex then
      return Complex(a.real + b.real, a.imag + b.imag) -- 复数相加
     elseif num_type == "number" then
      return Complex(a.real + b, a.imag) -- 复数加实数
    end
  end;
  
  __sub = function(a, b)
    local opst = -b
    return a + opst
  end;
  
  __unm = function(self)
    return Complex(-a.real, -a.imag)
  end;
  
  __mul = function(a, b)
    local num_type = luaclass(b)
    if num_type == Complex then
      return Complex(a.real*b.real - a.imag*b.imag, a.real*b.imag + a.imag*b.real)
     elseif num_type == "number" then
      return Complex(a.real * b, a.imag * b)
    end
  end;

  -- 自定义显示样式
  __tostring = function(self)
    local imag = self.imag
    if imag > 0 then
      return ("%d + %di"):format(self.real, imag)
     elseif imag < 0 then
      return ("%d - %di"):format(self.real, -imag)
     else
      return tostring(self.real)
    end
  end
}

local z1 = Complex(1, 2)
local z2 = Complex(3, 4)

print(z1 + z2) --> 4 + 6i
print(z1 * z2) --> -5 + 10i