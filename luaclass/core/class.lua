-- Luaclass 纯lua的基于类OOP机制

local _G, type, next, select, rawget, setmetatable, require, error
    = _G, type, next, select, rawget, setmetatable, require, error

if _ENV then _ENV = nil end -- 防止意外的 _G 访问

local isinstance = require("luaclass.inherit.isinstance")
local mergeMROs  = require("luaclass.inherit.mro")
local fromsuper  = require("luaclass.inherit.index")
local namespace  = require("luaclass.core.namespace")
local checktool  = require("luaclass.core.checktool")
local declare    = require("luaclass.share.declare")
local weaken     = require("luaclass.share.weaktbl")
local randstr    = require("luaclass.share.randstr")


---@param cls table luaclass 类对象
---@param ... any?  传递给构造函数的参数
---@return table obj 该类的一个实例
---这个方法是元类默认的 __call 方法  
---当类被调用时, 实际上是调用这个方法来创建实例  
local function new_instance(cls, ...)
  if rawget(cls, "abstract") then
    error((
      "Cannot instantiate abstract class '%s'"
    ):format(cls), 2)
  end

  local inst = cls:__new(...)
  local init = cls.__init
  
  if type(init) == "function" then
    init(inst, ...)
  end

  if cls.declare then
    local ok, err = checktool.isInitialized(cls, inst)
    if not ok then error(err, 2) end
  end

  return inst
end



-- 手动创建 luaclass 元类 和 Object 根类

local luaclass = {
  __classname  = "luaclass";
  __ns_name    = "lua.class";
  __tostring   = function(self) return self.__classname or "<anonymous>" end;
  __call       = new_instance;
  __index      = fromsuper; -- 实现继承 & 多态的关键
  defaultns    = "lua._G";
}

local Object   = {
  __classname  = "Object";
  __ns_name    = "lua.class";
  __tostring   = function(self) return ("<%s object>"):format(self.__class) end;
  __new        = function(self) return setmetatable({__class = self}, self) end;
  getClass     = function(self) return self.__class end;
  isInstance   = isinstance;
  toString     = _G.tostring;
  is           = _G.rawequal;
}

luaclass.__mro   = {luaclass, Object, n=2, lv={1, 1, n=2}}
Object.__mro     = {Object, n=1, lv={1, n=1}}

luaclass.__class = luaclass
Object.__class   = luaclass

setmetatable(luaclass, luaclass)
setmetatable(Object, luaclass)

-- 给这两个类定义类型符号
local typedef = declare.typedef

typedef(luaclass, "luaclass")
typedef(Object, "Object")


-- 创建 class 命名空间
namespace.new("lua.class", {
  luaclass   = luaclass;
  Object     = Object;
  isinstance = isinstance;
  namespace  = namespace;
  decl       = declare;
})

-- 匿名类命名空间
-- kv 弱表, 避免影响垃圾回收
namespace.new("lua.class.anonymous", weaken({}, 'kv'))


-- Lua 元方法名
local mm_names = {
  "__add", "__sub", "__mul", "__div", "__idiv", "__mod", "__pow",
  "__unm", "__band", "__bor", "__bxor", "__bnot", "__shl", "__shr",
  "__concat", "__len", "__eq", "__lt", "__le", "__call", "__gc",
  "__tostring"
}

---@classmethod
---创建对象或获取对象类型
function luaclass:__new(...)
  local arg_count = select('#', ...)

  if arg_count == 0 then
    error("bad argument #1 to 'luaclass:__new' (value expected)", 3)
  end

  -- 单参数调用时，返回对象的类
  if arg_count == 1 then
    local obj = ...
    local typ = type(obj)
    return (typ == "table" or typ == "string") and obj.__class or typ
  end

  local name, bases, tbl = ...

  if not bases or not bases[1] then
    bases = {Object} -- 默认继承 Object
  end

  -- 获取在名字中指定的命名空间
  local ns_name, name = name:match("^([^:]-):*([^:]+)$")

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
    new         = new_instance; -- 同时提供经典的实例化风格, clazz:new()
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


-- 类创建器，用于处理语法
local function class(name, bases)
  if not name or name == '' then -- 匿名类
    name = "lua.class.anonymous::Class_"
        .. randstr(10)
  end

  -- 先假设为 class "name" {} 语法
  -- 捕获成员表
  return function(tbl, ...)
    tbl = tbl or {}

    -- 处理 class "name" (bases) {} 语法
    if tbl.__classname then
      local firstBase = tbl
      return class(name, {firstBase, ...}) -- 捕获基类
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

    return new_instance(mcls, name, bases, tbl)
  end
end

return class
