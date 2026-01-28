-- luaclass/core/creator.lua
-- 类创建器

local checktool  = require "luaclass.core.checktool"
local luaclass   = require "luaclass.core.luaclass"
local randstr    = require "luaclass.share.randstr"

---@alias MenberReceiver fun(tbl:table):luaclass
---@alias BasesReceiver  fun(tbl:luaclass, ...:luaclass):MenberReceiver

---类创建器，用于处理语法
---@param name? string
---@param bases nil
---@return MenberReceiver|BasesReceiver
---@overload fun(name:string, bases:luaclass[]):MenberReceiver
local function class(name, bases)
    if not name or name == '' then -- 匿名类
        name = "lua.class.anonymous::Class_".. randstr(10)
    end
    
    -- 先假设为 class "name" {} 语法
    -- 捕获成员表
    
    ---@param tbl luaclass
    ---@param ... luaclass
    ---@return MenberReceiver
    ---@overload fun(tbl:table):luaclass
    return function(tbl, ...)
        tbl = tbl or {}

        if tbl.__classname then
            -- 处理 class "name" (bases) {} 语法
            -- 捕获基类
            local firstBase = tbl
            return class(name, {firstBase, ...})
        end

        -- 获取元类指定, 默认为 luaclass
        local mcls = tbl.metaclass or luaclass
        tbl.metaclass = nil

        -- 声明模式下记录声明的字段
        if tbl.declare then
            tbl.__declared = checktool.getDeclared(tbl, bases)
        end

        -- 抽象类记录抽象方法
        if tbl.abstract then
            tbl.__abstract_methods = checktool.getAbstractMethods(tbl, bases)
        end

        ---@type luaclass
        return mcls(name, bases, tbl)
    end
end

return class
