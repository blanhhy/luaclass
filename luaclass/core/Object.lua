local setmetatable = setmetatable
local isinstance   = require("luaclass.inherit.isinstance")

---@class luaclass
local Object   = {
    __classname  = "Object";
    __ns_name    = "lua.class";
    __tostring   = function(self) return ("<%s object>"):format(self.__class) end;
    __new        = function(self) return setmetatable({__class = self}, self) end;
    getClass     = function(self) return self.__class end;
    isInstance   = isinstance;
    toString     = tostring;
    is           = rawequal;
}

Object.__mro     = {Object}

return Object