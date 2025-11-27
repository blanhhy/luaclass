require "luaclass"

-- 这个文件演示如何使用经典 LuaOOP 风格的语法

require "luaclass.util.Class"
-- 需要额外导入 Class 元类
-- Class 的类签名是 _G::Class(class::luaclass)

-- 出于怀旧，便于理解，开发习惯，Lint工具不够强大等等各种原因，
-- Luaclass 提供了这个 Class 工具类，用于模拟 Lua 传统的 OOP

-- 用 Class 创建类
-- 参数是类名和基类列表 (name?: string, ...?: luaclass)
local Person = Class "Person"

-- Class 不接受定义体, 因此需要像传统方式一样手动加字段
function Person:__init(name)
  self.name = name
end

function Person:sayHello()
  print("Hello, I am "..self.name)
end

local p = Person("Bob")
p:sayHello() -- 输出: Hello, I am Bob


-- 因为是同一个体系, 所以和 luaclass 风格语法是兼容的
local Student = -- 用 local 是方便演示, 命名空间访问不是本文的重点
class "Student"(Person) {
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


-- 有很多传统的类库没有类名一说, 就靠一个变量名
-- Class也模拟了这种用法, 可以匿名创建, 实际类名将会是一个随机字符串
-- 命名空间则是 class.anonymous, 此命名空间为kv弱表, 不会延长匿名类的生命周期

-- 不带字符串参数 (可以有基类), 匿名创建类
local Animal = Class()

function Animal:__init(name)
  self.name = name
end

function Animal:speak()
  print(self.name.." makes a sound.")
end

local a = Animal("Lion")
a:speak() -- 输出: Lion makes a sound.

print(Animal.__classname) -- 输出类似 Class_xxxxxxxxxx


-- 注: 标准创建器也可以创建匿名类, name为空串或缺省即可
-- local clazz = class () {--[[定义体]]}


-- 其实你还可以这样定义, 视觉上可能会更好
Class "Book" do
  local _G = namespace._G
  local _ENV = namespace.class.Book
  
  function __init(self, name, desc)
    self.name = name or "untitled"
    self.desc = desc or "null"
  end
  
  function showInfo(self)
    _G.print(("Name: %s\nDescription: %s")
      :format(self.name, self.desc))
  end
end
