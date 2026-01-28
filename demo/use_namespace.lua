local namespace = require "luaclass.core.namespace"

-- 本文件演示一般情况下命名空间的用法, 这里没有引入 luaclass 库

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

-- 还有一个Lua更熟悉的写法:
-- namespace.new(ns_name[, content])

-- 命名空间是已导入的包, 所以可以require它
local Game = require "Game"
print(Game == namespace.Game) -- true

-- 使用命名空间
local _ENV = namespace.use()

-- 看到_ENV不要慌, 实际上兼容Lua5.1 (内部自动setfenv)
-- 如果你只使用Lua 5.1的话, 甚至不用接收这个返回值

-- 用using添加要使用的命名空间, 可以写多个using, 会按序查找 (如果有同名对象要注意这一点)
-- using既可以传入命名空间表对象, 也可以传入命名空间全名, 比如using'_G'和using(namespace._G)是等价的
-- using返回_ENV本身, 因此也可以链式调用
-- using并不是一个全局函数, 而是namespace.use返回的_ENV中特有的函数
using(namespace.Game.Deltarune)

-- import导入对象到本地_ENV中, 语法为import "命名空间.对象名"
-- 同样的, import也不是全局函数, 只有命名空间环境中才有
import "lua._G.print";
import "lua._G.pairs";

-- import对象名可以用*, 表示导入其中所有名字合法的对象
-- 如果多次导入的对象有重名, 后导入的不会覆盖先导入的, 也就是实际不会导入
-- 如果一定要导入, 可以先赋值为nil (从当前环境中删除)再导入

heros = {} -- 存放英雄信息的表(存在于本地_ENV中)
namespace.Game.Deltarune.heros = heros -- 把heros表放到命名空间中

-- 也可以用new把直接它也作为一个命名空间
-- namespace.new("Game.Deltarune.heros", heros)

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

-- 真正的命名空间容器是一个内部表, 你无法获取它
-- 但是获取其中的命名空间是没问题的: namespace.path.to.your_ns
-- 还可以遍历所有: for name, ns in namespace.iter do ... end
