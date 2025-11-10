local namespace = require "luaclass.core.namespace"

-- 本文件演示一般情况下命名空间的用法, 这里没有引入 luaclass 库

-- 定义一个命名空间, 包含三角符文的一些角色
-- 定义嵌套命名空间时, 自动创建父命名空间
namespace "Game.Deltarune.roles" {
  kris = { name = "kris dreemurr", is_hero = 1, ethnicity = "human", identity = "player container" };
  noelle = { name = "noelle holliday", is_hero = 2, ethnicity = "monster", identity = "angel" };
  ralsei = { name = "ralsei", is_hero = 3, ethnicity = "darkner", identity = "dark prince" };
  susie = { name = "susie", ethnicity = "monster", identity = "main character" };
  lancer = { name = "lancer", ethnicity = "darker", identity = "now i am the father!" };
  asgore = { name = "asgore dreemurr", ethnicity = "monster", identity = "flower king" };
  -- ...
}

-- 使用命名空间
local _ENV = namespace.use()

-- 用using添加要使用的命名空间, 第一个会被视为主命名空间, 新的变量会保存到主命名空间中
-- using并不是一个全局函数, 而是namespace.use返回的_ENV中特有的函数
using(namespace.Game.Deltarune) -- 主命名空间(可读可写)
using(namespace._G) -- 附加命名空间(只读)
-- using既可以传入命名空间表对象, 也可以传入命名空间全名, 比如using'_G'和using(namespace._G)是等价的

heros = {}

for _, role in pairs(roles) do
  if role.is_hero then
	heros[role.is_hero] = role
  end
end

print("the third hero in prophecy is a " .. heros[3].identity)
print("asgore's fullname is " .. roles.asgore.name)

-- 恢复到原来的环境, 不再使用命名空间
local _ENV = namespace._G
print(heros or "not in _G") -- 验证命名空间中的变量不在_G中

--[[ 输出:
the third hero in prophecy is a dark prince
asgore's fullname is asgore dreemurr
not in _G
]]
