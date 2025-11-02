require "luaclass"

-- 这个文件中我们主要演示如何声明字段以及进行类型检查。

-- 首先我们定义一个Tank类
class "_G::Tank" {
    declare = true; -- 开启声明模式

    -- 声明一些字段
    name = NULL.string; -- 坦克名字, 类型为string
    health = NULL.number; -- 坦克血量, 类型为number
    armor = NULL.number; -- 坦克护甲, 类型为number
    damage = NULL.number; -- 坦克攻击力, 类型为number

    --[[
    即使不开启声明模式, 也可以用NULL占位符声明字段, 但是在开启声明模式后:
    1. 声明的字段必须在构造函数中初始化为非nil值, 否则会报错.
    2. 声明的字段类型必须与初始化的值类型一致, 否则会报错.
    ]]

    __init = function(self, name, health, armor, damage)
        -- 由于开启了声明模式, 这里并不需要类型检查
        -- 但是实际应用中可以根据具体需求妥善的处理空值和类型错误, 比如默认值
        self.name = name;
        self.health = health;
        self.armor = armor;
        self.damage = damage;
    end;

    attack = function(self, target)

        -- 这里我们使用isinstance函数进行类型检查
        if not isinstance(target, self:getClass()) then
            print("Target is not a Tank!");
            return;
        end;

        target.health = target.health - self.damage;
        print("Tank " .. self.name .. " attacks " .. target.name .. " for " .. self.damage .. " damage!");
    end;

    heal = function(self, amount)
        -- 这里可以用type, 也可以用isinstance, isinstance是兼容基本类型的
        if not isinstance(amount, "number") then
            print("Heal amount is not a number!");
            return;
        end;

        self.health = self.health + amount;
        print("Tank " .. self.name .. " heals for " .. amount .. " health!");
    end;

    __tostring = function(self)
        return string.format("Tank(%s, HP:%d, AR:%d, DMG:%d)", self.name, self.health, self.armor, self.damage);
    end;
}


t1 = Tank("T1", 100, 50, 10);
t2 = Tank("T2", 100, 50, 10);

t1:attack(t2);
t2:attack(t1);

t1:heal(50);

print(t1);
print(t2);

-- ==============================

-- 正确输出:
-- Tank T1 attacks T2 for 10 damage!
-- Tank T2 attacks T1 for 10 damage!
-- Tank T1 heals for 50 health!
-- Tank(T1, HP:140, AR:50, DMG:10)
-- Tank(T2, HP:90, AR:50, DMG:10)


-- 类型错误的例子
t1:attack("T2"); -- 错误: 目标不是一个Tank对象
local t3 = Tank("T3", 100, 50, '10'); -- 错误: 攻击力不是数字类型

-- 输出:
--[[
Target is not a Tank!
xxx.lua:70: Initializing declared field 'damage: number' with a string value in instance of class '_G::Tank'
stack traceback:
	[C]: in function 'error'
	xxx/luaclass/luaclass.lua:42: in function 'luaclass.__call'
	xxx.lua:70: in main chunk
	[C]: in ?
]]