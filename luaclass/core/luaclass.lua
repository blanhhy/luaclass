local type, next, select, rawget, setmetatable, require, error
    = type, next, select, rawget, setmetatable, require, error

local unpack = table.unpack or unpack

if _ENV then _ENV = nil end -- 本文件较为复杂, 这样能防止意外的 _G 访问

local fromsuper  = require("luaclass.inherit.index")
local isinstance = require("luaclass.inherit.isinstance")
local mergeMROs  = require("luaclass.inherit.mro")
local namespace  = require("luaclass.core.namespace")
local checktool  = require("luaclass.core.checktool")
local Object     = require("luaclass.core.Object")
local randstr    = require("luaclass.share.randstr")
local typedef    = require("luaclass.share.declare").typedef

---@class luaclass
local luaclass = {
    __classname  = "luaclass";
    __ns_name    = "lua.class";
    __tostring   = function(self) return self.__classname or "<anonymous>" end;
    __index      = fromsuper; -- 实现继承 & 多态的关键
    defaultns    = "lua._G";
}

---@alias type_class luaclass|type       含类对象的类型
---@alias type_check luaclass|type|"any" 可以检查的类型

---@class type_mismatch
---@field [1]      integer
---@field [2]      table|type
---@field [3]      table|type
---@field pos      integer
---@field expected table|type
---@field actual   table|type
---@field unpack fun(t: type_mismatch): (integer, table|type, table|type)

---@static
---@param ... any 成对的 “值, 类型” 参数列表
---@return type_mismatch?
---@overload fun(v1:any, T1?:type_check, v2?:any, T2?:type_check, v3?:any, T3?:type_check, ...:any): type_mismatch?
function luaclass.match(...)
    local n = select('#', ...)
    if n == 0 then return end

    local list = n == 1 and type(...) == "table"
        and (...)
        or  {...}

    if n % 2 == 1 then
        n = n + 1
        list[n] = "any"
    end

    for i = 1, n, 2 do
        if not isinstance(list[i], list[i+1]) then
            local type_mismatch = {
                pos = (i+1) / 2,
                expected = list[i+1],
                actual = luaclass(list[i]),
                unpack = unpack
            }
            type_mismatch[1] = type_mismatch.pos
            type_mismatch[2] = type_mismatch.expected
            type_mismatch[3] = type_mismatch.actual
            return type_mismatch
        end
    end
end


-- Lua 元方法名
local mm_names = {
    "__add", "__sub", "__mul", "__div", "__idiv", "__mod", "__pow",
    "__unm", "__band", "__bor", "__bxor", "__bnot", "__shl", "__shr",
    "__concat", "__len", "__eq", "__lt", "__le", "__call", "__gc",
    "__tostring"
}

---创建类对象
---@classmethod
---@param name?  string
---@param bases? luaclass[]
---@param tbl?   table
---@return luaclass
---@overload fun(self: luaclass, name: string, bases: luaclass[], tbl: table): luaclass
---@overload fun(self: luaclass, name: string, bases: luaclass[]): luaclass
---@overload fun(self: luaclass, name: string): luaclass
---@overload fun(self: luaclass): luaclass
function luaclass:__new(name, bases, tbl)
    local ns_name

    if not name or name == '' then -- 匿名类
        ns_name = "lua.class.anonymous"
        name = "Class_".. randstr(10)
    end
    
    if not bases or not bases[1] then
        bases = {Object} -- 默认继承 Object
    end

    -- 获取在名字中指定的命名空间
    if not ns_name then
        ns_name, name = name:match("^([^:]-):*([^:]+)$")
    end

    if not ns_name or ns_name == '' then
        ns_name = self.defaultns -- 默认命名空间
    elseif ns_name:sub(1, 1) == '.' then
        ns_name = self.defaultns..ns_name -- 相对路径
    end

    local cls = {
        __classname = name;
        __ns_name   = ns_name;
        __class     = self;
        __new       = Object.__new;
    }

    cls.__index = cls

    -- 复制所有成员到类中
    if tbl then for k, v in next, tbl do
        cls[k] = v
    end end

    local as_abc = cls.abstract -- 是否作为抽象类创建
    local as_type = cls.typedef -- 是否作为可声明的类型创建

    -- 计算MRO
    local mro, err = mergeMROs(cls, bases)
    if err then error(err, 2) end

    cls.__mro = mro
    setmetatable(cls, self) -- 元类是类的元表

    -- Lua 不从 __index 中查找元方法, 只好直接复制了
    local mm_name, base_mm

    for i = 1, #mm_names do
        mm_name = mm_names[i]
        base_mm = not rawget(cls, mm_name) and cls[mm_name]
        if base_mm then cls[mm_name] = base_mm end
    end

    cls.abstract = nil -- 这会让下面的 cls.abstract 访问到基类的 abstract 属性

    -- 子类未声明抽象但基类抽象, 需要检查抽象方法实现没有
    if not as_abc and cls.abstract then
        local ok, err = checktool.isImplemented(cls, bases)
        if not ok then error(err, 2) end
        cls.abstract = false -- 必须设置成 false 而不是 nil, 要阻断对子类的影响
    end

    -- 注册类到对应的命名空间
    local ns = namespace.get(ns_name)
    ns[name] = cls

    -- 给类定义一个类型名, 可用于以后的字段声明
    if as_type then
        cls.typedef = type(as_type) == "string"
        and as_type
        or (ns_name.."::"..name)
        typedef(cls, cls.typedef)
    end

    return cls
end


---这个方法是元类默认的 __call 方法  
---当类被调用时, 实际上是调用这个方法来创建实例
---@param ... any      传递给构造函数的参数
---@return Object obj  该类的一个实例
---@overload fun(val: any):type_class
function luaclass:__call(...)
    if self == luaclass and select('#', ...) == 1 then
        local obj, typ = (...), type(...)
        return (typ == "table" or typ == "string") 
        and obj.__class
        or  typ
    end

    if self ~= luaclass and rawget(self, "abstract") then
        error((
        "Cannot instantiate abstract class '%s'"
        ):format(self), 2)
    end

    local inst = self:__new(...)
    local init = self.__init

    if init and type(init) == "function" then
        init(inst, ...)
    end

    if self.declare then
        local ok, err = checktool.isInitialized(self, inst)
        if not ok then error(err, 2) end
    end

    return inst
end

return luaclass