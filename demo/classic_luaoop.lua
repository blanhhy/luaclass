require "luaclass.Class"

-- 演示: 在 luaclass 中使用经典 LuaOOP 风格的语法

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

class "ChinesePerson"(Person) {
  -- 注: 经典语法不指定命名空间默认是 _G
  -- 而用 luaclass 创建的类命名空间默认是 class
  namespace = _G;
  
  ---@Override
  sayHello = function(self)
    print("你好，我叫"..self.name)
  end
}

local cp = ChinesePerson("小明")
cp:sayHello() -- 输出: 你好，我叫小明
