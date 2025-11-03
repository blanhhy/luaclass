local _G, error, pcall, select = _G, error, pcall, select

local pack = _G.table.pack or function(...)return{n=select('#',...),...}end
local unpack = _G.table.unpack or _G.unpack
local pop = _G.table.remove

-- 导入luaclass的一些工具
local luaclass = _G.require "luaclass.luaclass"
local class = luaclass.__export.class
local isinstance = luaclass.__export.isinstance



local try, catch, finally, throw, Exception -- 要定义的对象

Exception = class "Exception" {
    __init = function(self, message)
        self.message = message
    end,
    __tostring = function(self)
        return ("%s: %s")
            :format(self.getClass().toString(), self.message)
    end
}

throw = error
