require "luaclass"

-- 这个文件简单演示一下luaclass里的抽象类
--
-- 抽象类是在引入声明模式之后自然出现的, 本来并不是计划中的更新内容
-- 具体来说, decl 占位符中有一个函数类型, 写法是 decl.method
--
-- 含有 decl.method 的类会因为声明字段初始化检查而不能实例化, 而实现了这个方法的子类则可以
-- 这时候 decl.method 就成了抽象方法, 而这个类自然成了抽象类
--
-- 现在, 我添加了单独的 abstract 字段, 不必依赖声明模式
-- 声明了 abstract = true 的类会成为抽象类, 无法实例化
-- 抽象类的子类必须要么也是抽象类, 要么实现所有抽象方法, 否则在定义类时报错


-- 这是一个抽象的Animal类, 它不能实例化, 并且有 eat 和 move 方法待实现
class "Animal" {
--  declare = true; -- 不再对抽象类必要
	abstract = true;
	eat  = decl.method;
	move = decl.method;
}

-- 飞行能力抽象类
-- fly 方法待实现
class "CanFly" {
	abstract = true;
	fly = decl.method;
}


class "Sheep"(Animal) {
	---@Override
	eat = function(self)
		print(self:getClass():toString().." eats grass.")
	end;

	---@Override
	move = function(self)
		print(self:getClass():toString().." walks on legs.")
	end;
}

-- 多继承, 有疑问的参考MRO的那个demo
class "Sparrow"(Animal, CanFly) {
	---@Override
	eat = function(self)
		print(self:getClass():toString().." eats insects.")
	end;

	---@Override
	move = function(self)
		return self:fly() -- 简单起见, 这里直接委托 fly 方法
	end;

	---@Override
	fly = function(self)
		print(self:getClass():toString().." flys.")
	end
}


local sheep = Sheep()
sheep:eat()
sheep:move()

local sparrow = Sparrow()
sparrow:eat()
sparrow:move()

--[[
输出:
Sheep eats grass.
Sheep walks on legs.
Sparrow eats insects.
Sparrow flys.
]]


-- 错误示范:
xpcall(function()
  class "Dog" (Animal) {}
end, print)
-- 报错, 因为Dog类既没有声明为抽象类也没有实现基类的eat和move方法
-- class 'Dog' is not abstract and does not override abstract method 'eat'
