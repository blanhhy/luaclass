require "luaclass"
require "luaclass.util.Class" -- 需要导入 Class 元类

-- 这个文件演示了如何在 luaclass 中使用经典 LuaOOP 风格的语法

local Person = Class"Person"

function Person:__init(name)
  self.name = name
end

function Person:sayHello()
  print("Hello, I am "..self.name)
end

local p = Person("Bob")
p:sayHello() -- 输出: Hello, I am Bob


-- 经典语法与 luaclass 语法共用同一套系统, 因此是完全兼容的
-- 命名空间不指定默认会加上class::前缀, 正常使用需要using命名空间或者指定为_G
-- 这里为了演示方便就直接local返回值了

local Student =
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


-- 还可以匿名创建, 实际类名将会是一个随机字符串
-- 命名空间则是class.anonymous, 此命名空间为kv弱表, 不会延长匿名类的生命周期
local Animal = Class() -- 匿名类

function Animal:__init(name)
  self.name = name
end

function Animal:speak()
  print(self.name.." makes a sound.")
end

local a = Animal("Lion")
a:speak() -- 输出: Lion makes a sound.

print(Animal.__classname) -- 输出类似 Class@xxxxxxxxxx (不是lua标识符)
