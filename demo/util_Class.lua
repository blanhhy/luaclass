require "luaclass"

-- 这个文件演示如何使用经典 LuaOOP 风格的语法

-- 需要额外导入 Class 元类
-- Class 的类签名是 _G::Class(class::luaclass)

require "luaclass.util.Class"

-- 出于怀旧, 开发习惯, 原理理解, Lint工具不够强大等等各种原因,
-- Luaclass 提供了这个 Class 工具类, 用于模拟传统的 OOP 形式

-- 用 Class 创建类
-- 参数是类名和基类列表 (name?: string, ...?: luaclass)
-- Class 被设计为不接受定义体, 所以字段只能后续添加
local Person = Class "Person"

function Person:__init(name)
  self.name = name
end

function Person:sayHello()
  print("Hello, I am "..self.name)
end

local p = Person("Bob")
p:sayHello() -- 输出: Hello, I am Bob


-- 因为是同一个体系, 所以和 luaclass 风格语法是兼容的
-- 不过也由于 Class 不接受定义体, 你不能在标准创建器中指定 metaclass = Class;
-- 即使它确实是一个元类 (如果那样做了定义体被会忽略, 和直接实例化 Class 没有不同)

-- 用标准创建器创建类, 并继承刚才的类
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

local stu = Student("Alice", 10)
stu:sayHello()
-- 输出: Hello, I am Alice and my grade is 10


-- 有很多传统的类库没有类名一说, 就靠一个变量名
-- Class 也模拟了这种用法, 可以匿名创建, 实际类名将会是一个随机字符串
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


-- Class 一种别具风格的用法:
-- 装作是在一起定义而不是稍后添加
-- 视觉上可能更好, 还能解决不能折叠整个类的问题
-- 注意，_ENV块级作用域在 lua5.2 以后才适用, luajit 里不能用这种写法
xpcall(function()

local Book = Class "Book" do
  local _G = _G
  local _ENV = Book

  function __init(self, name, desc)
    self.name = name or "untitled"
    self.desc = desc or "null"
  end

  function showInfo(self)
    _G.print(("BookName: %s\nDescription: %s")
      :format(self.name, self.desc))
  end
end

local lldq = Book("流浪地球", "《流浪地球》是刘慈欣的一部科幻小说，讲述了人类为了逃离太阳即将变成红巨星的灾难，决定带着地球离开太阳系，前往比邻星的惊险历程。")
lldq:showInfo()

end, function() print "Lua5.2以上适用" end)