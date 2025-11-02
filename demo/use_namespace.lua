local namespace = require "luaclass.namespace"


namespace "Game.Deltarune.roles" {
  kris = { name = "kris dreemurr", is_hero = 1, ethnicity = "human", identity = "player container" };
  noelle = { name = "noelle holliday", is_hero = 2, ethnicity = "monster", identity = "angel" };
  ralsei = { name = "ralsei", is_hero = 3, ethnicity = "darkner", identity = "dark prince" };
  susie = { name = "susie", ethnicity = "monster", identity = "main character" };
  lancer = { name = "lancer", ethnicity = "darker", identity = "now i am the father!" };
  asgore = { name = "asgore dreemurr", ethnicity = "monster", identity = "flower king" };
  -- ...
}

local _ENV = namespace.use()

using(namespace.Game.Deltarune) -- 主命名空间(可读可写)
using(namespace._G) -- 附加命名空间(只读)

heros = {}

for _, role in pairs(roles) do
  if role.is_hero then
	heros[role.is_hero] = role
  end
end

print("the third hero in prophecy is a " .. heros[3].identity)
print("asgore's fullname is " .. roles.asgore.name)

local _ENV = namespace._G
print(heros or "not in _G")

--[[ 输出:
the third hero in prophecy is a dark prince
asgore's fullname is asgore dreemurr
not in _G
]]