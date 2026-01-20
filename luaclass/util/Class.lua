if not class then
    require "luaclass"
end

-- 这个类需要单独导入, require "luaclass" 的时候并不会包含luaclass.util.*

local randstr = require "luaclass.share.randstr"
local __new   = luaclass.__new
local type    = _G.type

local Class

-- 创建一个元类, 用于适配 lua 经典 OOP 语法
Class = class "Class"(luaclass) {
    defaultns = luaclass.defaultns;

    ---@Override
    ---@Classmethod
    __new = function(cls, name, ...)
        local bases
        local t = type(name)
        if t == "nil" or t == "table" then
            bases = {name, ...}
            name  = "lua.class.anonymous::Class_"..randstr(10) -- 生成随机类名
        elseif t == "string" then
            bases = {...}
        end
        return __new(cls, name, bases)
    end;
}


return Class