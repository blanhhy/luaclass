require "luaclass"
require "luaclass.util.Class" -- 需要导入 Class 元类

-- 这个文件演示了如何在 luaclass 中使用经典 LuaOOP 风格的语法

local Person = Class'Person'

function Person:__init(name)
  self.name = name
end

function Person:sayHello()
  print("Hello, I am "..self.name)
end

local p = Person("Bob")
p:sayHello() -- 输出: Hello, I am Bob


-- 经典语法与 luaclass 语法共用同一套系统, 因此是完全兼容的

-- 注:
-- 经典语法不指定命名空间默认是 _G, 而用 luaclass 创建的类命名空间默认是 class
-- 不用担心, 因为不论如何显式指定都是有效的

class "_G::Student"(Person) {
  ---@Override
  __init = function(self, name, grade)
    super(self):__init(name)
    self.grade = grade
  end;

  ---@Override
  sayHello = function(self)
    print("Hello, I am "..self.name.." and my grade is "..self.grade)
  end;
}

local s = Student("Alice", 10)
s:sayHello() -- 输出: Hello, I am Alice and my grade is 10
