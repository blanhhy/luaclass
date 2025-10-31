local luaclass = require "luaclass"
local Object   = Object

local Class

-- 创建一个元类, 用于适配 lua 经典 OOP 语法
Class = class "_G::Class"(luaclass) {
    ---@Override,@Classmethod
    __new = function(self, name, bases)
		-- 简单起见, 用 Class() 创建的类默认命名空间 _G, 而不是 class
		if not name:find(':', 1, true) then
			name = '_G:' .. name
		end
        return luaclass:__new(name, bases)
    end
}

return Class