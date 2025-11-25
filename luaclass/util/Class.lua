assert(luaclass, "luaclass required!")

-- 这个类需要单独导入, require "luaclass" 的时候并不会包含luaclass.util.*

-- local checktool = require "luaclass.core.checktool"
-- local declare   = require "luaclass.share.declare"

local Class

-- 创建一个元类, 用于适配 lua 经典 OOP 语法
Class = class "_G::Class"(luaclass) {
    ---@Override,@Classmethod
    __new = function(_, name, ...)
		-- 简单起见, 用 Class() 创建的类默认命名空间 _G, 而不是 class
		if not name:find(':', 1, true) then
			name = '_G::' .. name
		end
        return luaclass:__new(name, {...})
    end;
}

return Class