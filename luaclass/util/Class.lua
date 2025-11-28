assert(package.loaded.luaclass, "luaclass required!")

-- 这个类需要单独导入, require "luaclass" 的时候并不会包含luaclass.util.*

local namespace = require "luaclass.core.namespace"
local randstr   = require "luaclass.share.randstr"

local class     = namespace.class.class
local type      = namespace.class.luaclass
local rawtype   = namespace._G.type


local Class

-- 创建一个元类, 用于适配 lua 经典 OOP 语法
---@type table|fun(name?:string, ...?:table):table
Class = class "_G::Class"(type) {
    defaultNS = "class"; -- 是这个元类创建的类的默认命名空间位置
    ---@Override,@Classmethod
    __new = function(_, name, ...)
        local bases
        local t = rawtype(name)
        if t == "nil" or t == "table" then
            bases = {name, ...}
            name  = "class.anonymous::Class_"..randstr(10) -- 生成随机类名
        elseif t == "string" then
            bases = {...}
        end
        return type:__new(name, bases)
    end;
}


return Class