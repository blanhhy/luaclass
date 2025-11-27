assert(package.loaded.luaclass, "luaclass required!")

-- 这个类需要单独导入, require "luaclass" 的时候并不会包含luaclass.util.*

local namespace = require "luaclass.core.namespace"
local weaken    = require "luaclass.share.weaktb"
local randstr   = require "luaclass.share.randstr"

namespace.new("class.anonymous", weaken({}, 'kv'))

local class     = namespace.class.class
local type      = namespace.class.luaclass
local rawtype   = namespace._G.type

local Class

-- 创建一个元类, 用于适配 lua 经典 OOP 语法
Class = class "_G::Class"(type) {
    ---@Override,@Classmethod
    __new = function(_, name, ...)
        local bases
        local t = rawtype(name)
        if t == "nil" or t == "table" then
            bases = {name, ...}
            name  = "class.anonymous::Class@"..randstr(10) -- 生成随机类名
        elseif t == "string" then
            bases = {...}
        end
        return type:__new(name, bases)
    end;
}

return Class