require "luaclass"

-- 这个文件简单演示一下 luaclass 里的抽象类
--
-- 声明了 abstract = true 的类会成为抽象类, 无法实例化
-- 抽象类中声明的 decl.method 会被视为抽象方法 (可以没有抽象方法)
-- 抽象类的子类必须要么也是抽象类, 要么实现所有抽象方法, 否则在定义类时报错
-- 抽象类常常和声明模式同时使用, 但不是必须的

-- 这是一个抽象的 Animal 类, 它不能实例化, 并且有 eat 和 move 方法待实现
class "Animal" {
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

-- 多继承, 有疑问的参考 MRO 的那个 demo
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
-- 报错, 因为 Dog 类既没有声明为抽象类也没有实现基类的 eat 和 move 方法
-- class 'Dog' is not abstract and does not override abstract method 'eat'
