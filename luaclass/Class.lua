local luaclass = require "luaclass"
local _G = _G
local Class

-- 创建一个元类，用于适配lua经典OOP语法
Class = class "Class"(luaclass) {
	namespace = _G;
	
    ---@Override,@Classmethod
    __new = function(self, name, bases, ns)
        return super(self):__new(name, bases, {namespace = ns or _G})
    end
}

return Class