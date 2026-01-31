local setmetatable = setmetatable
local isinstance   = require("luaclass.inherit.isinstance")

---@class Object
---@field __class luaclass
---@field [any] any 成员

---@class luaclass: Object, metatable
---@field __classname string 类名
---@field __ns_name   string 命名空间名
---@field __mro       MRO    方法解析顺序
---@field __tostring  fun(self:luaclass):string 类名字符串化
---@field __index     fun(self:luaclass, name:string):any 超类成员查找
---@field __init      fun(self:Object, ...:any)? 对象构造函数
---@field __new       fun(self:luaclass, ...:any):Object 类实例化方法
---@field new         fun(self:luaclass, ...:any):Object 类实例化方法
---@field defaultns   string?  默认命名空间
---@field typedef     string?  可声明的类型名
---@field getClass    fun(self:Object):luaclass 获取对象的类
---@field isInstance  fun(self:Object, class:luaclass):boolean 判断对象是否为指定类的实例
---@field toString    fun(self:Object):string 对象字符串化
---@field is          fun(self:Object, other:Object):boolean 对象比较

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