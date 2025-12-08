local namespace = require "luaclass.core.namespace"

-- 本文件演示一般情况下命名空间的用法, 这里没有引入 luaclass 库

-- 一般功能:
-- 从命名空间中导入对象(须以lua开头, 表示从lua而不是外部导入)
local sin = require "lua.math.sin"
local PI = require "lua.math.pi"

print("sin(pi/6) =", sin(PI/6)) -- 输出: sin(pi/6) = 0.5

-- 定义一个命名空间, 包含三角符文的一些角色
-- 定义嵌套命名空间时, 自动创建父命名空间
namespace "Game.Deltarune.roles" {
  kris = { name = "kris dreemurr", is_hero = 1, ethnicity = "human", identity = "player container" };
  noelle = { name = "noelle holliday", is_hero = 2, ethnicity = "monster", identity = "angel" };
  ralsei = { name = "ralsei", is_hero = 3, ethnicity = "darkner", identity = "dark prince" };
  susie = { name = "susie", ethnicity = "monster", identity = "main character" };
  lancer = { name = "lancer", ethnicity = "darkner", identity = "spade prince" };
  asgore = { name = "asgore dreemurr", ethnicity = "monster", identity = "flower king" };
  -- ...
}

-- 特殊功能:
-- 使用命名空间
local _ENV = namespace.use()

-- 用using添加要使用的命名空间, 可以写多个using, 会按序查找(如果有同名对象要注意这一点)
-- using既可以传入命名空间表对象, 也可以传入命名空间全名, 比如using'_G'和using(namespace._G)是等价的
-- using返回_ENV本身, 因此也可以链式调用
-- using并不是一个全局函数, 而是namespace.use返回的_ENV中特有的函数
using(namespace.Game.Deltarune)

-- import导入对象到本地_ENV中, 语法为import "[lua.]命名空间.对象名"
-- 同样的, import也不是全局函数, 只有命名空间环境中才有
import "lua._G.print";
import "lua._G.pairs";

-- import对象名可以用*, 表示导入其中所有名字合法的对象
-- 如果多次导入的对象有重名, 后导入的不会覆盖先导入的, 也就是实际不会导入
-- 如果一定要导入, 可以先赋值为nil, 从当前环境中删除再导入

heros = {} -- 存放英雄信息的表(存在于本地_ENV中)
namespace.Game.Deltarune.heros = heros -- 把heros表放到命名空间中
-- namespace.new("Game.Deltarune.heros", heros) -- 也可以用new把它作为一个命名空间

for _, role in pairs(roles) do
  if role.is_hero then
	heros[role.is_hero] = role
  end
end

print("the third hero in prophecy is a " .. heros[3].identity)
print("asgore's fullname is " .. roles.asgore.name)

print(_G.heros or "not in _G") -- 验证命名空间中的变量不在_G中

--[[
输出:
the third hero in prophecy is a dark prince
asgore's fullname is asgore dreemurr
not in _G
]]

