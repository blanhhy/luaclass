require "luaclass"

-- 这个文件简单演示一下luaclass里的抽象类
--
-- PS: 这并不是我计划中的更新内容, 但是这个特性自己出现了
-- 所以仓促地写了这个 demo
-- 
-- 抽象类是在引入声明模式之后自然出现的
-- 具体来说, decl 占位符中有一个函数类型, 写法是 decl.method
-- 
-- 让我们回顾一下声明模式的特点: 
-- 声明的字段必须在实例化前初始化为正确的类型, 否则在实例化时报错
-- 
-- 一般在初始化发生在__init中, 但是, 子类的函数重写也可以实现这一点
-- 所以含有 decl.method 的基类不能直接实例化, 而实现了这个方法的子类可以实例化
-- 这时候 decl.method 就成了抽象方法, 而这个类自然成了抽象类


-- 这是一个抽象的Animal类
-- 它不能实例化, 因为 eat 和 move 方法待实现
class "_G::Animal" {
	declare = true; -- 要使用抽象类, 必须打开声明模式
	eat  = decl.method;
	move = decl.method;
}

-- 飞行能力抽象类
-- fly 方法待实现
class "_G::CanFly" {
	declare = true;
	fly = decl.method;
}


class "_G::Sheep"(Animal) {
	declare = true; -- 不写也可以, 因为会从父类继承, 但是写了更清晰
	
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
class "_G::Sparrow"(Animal, CanFly) {
	declare = true;
	
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
