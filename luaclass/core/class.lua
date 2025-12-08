--
-- Luaclass 纯lua的基于类OOP机制

local _G, type, next, select, rawget, setmetatable
    = _G, type, next, select, rawget, setmetatable

local require = _G.require

local isinstance = require("luaclass.inherit.isinstance")
local mergeMROs  = require("luaclass.inherit.mro")
local fromsuper  = require("luaclass.inherit.index")
local namespace  = require("luaclass.core.namespace")
local checktool  = require("luaclass.core.checktool")
local declare    = require("luaclass.share.declare")
local weaken     = require("luaclass.share.weaktb")
local randstr    = require("luaclass.share.randstr")


-- 类的实例化
-- 是元类的__call方法
local function new_instance(cls, ...)

  -- 抽象类不能实例化！
  if rawget(cls, "abstract") then
    _G.error(("Cannot instantiate abstract class '%s'")
      :format(cls), 2)
  end

  local inst = cls:__new(...) -- 调用构造函数
  local init = cls.__init -- 如果有初始化函数，调用它
  if init then init(inst, ...) end

  -- 如果声明了字段, 检查是否正确初始化
  if cls.declare then
    local ok, err = checktool.isInitialized(cls, inst)
    if not ok then _G.error(err, 2) end
  end

  return inst
end


local luaclass = {
  __classname  = "luaclass";
  __ns_name    = "class";
  __tostring   = function(self) return self.__classname or "<anonymous>" end;
  __call       = new_instance;
  __index      = fromsuper;
} -- 基本元类

local Object   = {
  __classname  = "Object";
  __ns_name    = "class";
  __tostring   = function(self) return ("<%s object>"):format(self.__class.__classname) end;
  __new        = function(self) return setmetatable({__class = self}, self) end;
  isInstanceOf = isinstance;
  getClass     = function(self) return self.__class end;
  toString     = _G.tostring;
} -- 根类

luaclass.__mro   = {luaclass, Object, n=2, lv={1, 1, n=2}}
Object.__mro     = {Object, n=1, lv={1, n=1}}

luaclass.__class = luaclass
Object.__class   = luaclass

setmetatable(luaclass, luaclass)
setmetatable(Object, luaclass)

local typedef = declare.typedef

typedef(luaclass, "luaclass")
typedef(Object, "Object")


-- 所有类的默认命名空间
-- 如果创建时不指定命名空间, 默认添加到这里
local class_NS = namespace.new(
"class", {
  luaclass = luaclass;
  Object   = Object;

  isinstance = isinstance;
  namespace  = namespace;
  decl       = declare;

  std = _G;
})

-- 匿名类命名空间
-- kv 弱表, 避免影响垃圾回收
namespace.new("class.anonymous", weaken({}, 'kv'))


local mm_names = {
  "__add", "__sub", "__mul", "__div", "__idiv", "__mod", "__pow",
  "__unm", "__band", "__bor", "__bxor", "__bnot", "__shl", "__shr",
  "__concat", "__len", "__eq", "__lt", "__le", "__call", "__gc"
}


-- 创建一个类
function luaclass:__new(...)
  local arg_count = select('#', ...)

  if arg_count == 0 then
    _G.error("bad argument #1 to 'luaclass:__new' (value expected)", 3)
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
  ns_name = ns_name and ns_name ~= '' and ns_name or (self.defaultNS or "class")

  local cls = {
    __classname = name;
    __ns_name   = ns_name;
    __class     = self;
    __new       = Object.__new; -- 这个方法比较常用
    __tostring  = Object.__tostring;
  }

  cls.__index = cls

  -- 复制所有成员到类中
  if tbl then
    for k, v in next, tbl do
      cls[k] = v
    end
  end

  local as_abc = cls.abstract -- 是否作为抽象类创建
  local as_type = cls.typedef -- 是否作为可声明的类型创建

  -- 计算MRO
  local mro, err = mergeMROs(cls, bases)
  if err then _G.error(err, 3) end

  cls.__mro = mro
  setmetatable(cls, self) -- 元类是类的元表

  -- 由于 Lua 不从 __index 中查找元方法
  -- 所以要继承元方法只好从基类中复制
  local mm_name, base_mm

  for i = 1, #mm_names do
    mm_name = mm_names[i]
    base_mm = not rawget(cls, mm_name) and cls[mm_name]
    if base_mm then
      cls[mm_name] = base_mm
    end
  end

  -- 如果基类抽象而子类不抽象
  -- 检查子类是否实现了所有的方法, 否则无法创建类
  if not as_abc and nil ~= cls.abstract then
    local ok, err = checktool.isImplemented(cls, bases)
    if not ok then _G.error(err, 3) end
    cls.abstract = false
  end

  -- 注册类到对应的命名空间
  local ns = namespace.get(ns_name)
  ns[name] = cls

  -- 给类定义一个类型名, 可用于以后的字段声明
  if as_type then
    local typename = type(as_type) == "string" and as_type or (ns_name.."::"..name)
    typedef(cls, typename)
    cls.typedef = typename
  end

  return cls
end


-- 类创建器，用于处理语法
local function class(name, bases)
  if not name or name == '' then
    name = "class.anonymous::Class_"
        .. randstr(10) -- 匿名类
  end

  return function(tbl, ...) -- 捕获成员表
    tbl = tbl or {}

    -- 如果获取到的是一个类
    if tbl.__classname then
      local firstBase = tbl
      return class(name, {firstBase, ...}) -- 捕获基类
    end

    local mcls = tbl.metaclass or luaclass -- 支持指定元类，默认 luaclass
    tbl.metaclass = nil

    -- 声明模式记录静态声明的字段
    if tbl.declare then
      tbl.__declared = checktool.getDeclared(tbl, bases)
    end

    -- 抽象类记录抽象方法
    if tbl.abstract then
      tbl.__abstract_methods = checktool.getAbstractMethods(tbl, bases)
    end

    return mcls(name, bases, tbl) -- 调用元类创建类
  end
end

return class