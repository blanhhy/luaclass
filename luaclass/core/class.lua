--
-- Luaclass 纯lua的基于类OOP机制

local _G, type, next, select, rawget, setmetatable
    = _G, type, next, select, rawget, setmetatable

local mergeMROs = _G.require("luaclass.inherit.mro")
local fromsuper = _G.require("luaclass.inherit.index")
local namespace = _G.require("luaclass.core.namespace")
local declare   = _G.require("luaclass.core.declare")


local function isinstance(obj, cls)
  local typ = type(obj)
  local obj_cls = typ == "table" and obj.__class

  if not cls then return obj_cls or typ end -- 单参数时返回类型
  if not obj_cls then return typ == cls or "any" == cls end -- Lua 基本类型兼容

  local mro = obj_cls.__mro

  for i = 1, mro.n do
    if cls == mro[i] then return true end -- 认为子类实例也是基类类型
  end
  return false
end

-- 类的实例化
local function new_instance(cls, ...)
  local inst = cls:__new(...) -- 调用构造函数
  local declared, decl_count

  -- 类是否使用声明模式
  if cls.declare then
    declared, decl_count = {}, 0
    for k, v in next, cls do
      if declare.type[v] then
        declared[decl_count + 1] = k
        decl_count = decl_count + 1
      end
    end
  end
  
  -- 如果有初始化函数，调用它
  local init = cls.__init
  if init then init(inst, ...) end

  -- 在声明模式下, 检查是否有未初始化字段以及类型匹配
  if declared then
    local field, value -- 字段名和初始化后的值
    for i = 1, decl_count do
      field = declared[i]
      value = rawget(inst, field)
      if nil == value then
        _G.error(("Uninitialized declared field '%s' in instance of class '%s'")
          :format(field.. ": " ..declare.type[cls[field]], cls.__ns_name.. "::" ..cls.__classname), 2)
      end
      if not isinstance(value, declare.type[cls[field]]) then
        _G.error(("Initializing declared field '%s' with a %s value in instance of class '%s'")
          :format(field.. ": " ..declare.type[cls[field]], isinstance(value), cls.__ns_name.. "::" ..cls.__classname), 2)
      end
    end
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

declare.typedef(luaclass, "luaclass")
declare.typedef(Object, "Object")


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


local mm_names = {
  "__add", "__sub", "__mul", "__div", "__idiv", "__mod", "__pow",
  "__unm", "__band", "__bor", "__bxor", "__bnot", "__shl", "__shr",
  "__concat", "__len", "__eq", "__lt", "__le", "__call", "__gc"
}

-- 创建一个类
function luaclass.__new(mcls, ...)
  local arg_count = select('#', ...)

  if arg_count == 0 then
    _G.error("bad argument #1 to 'luaclass.__new' (value expected)", 3)
  end

  -- 单参数调用时，返回对象的类
  if arg_count == 1 then
    local obj = ...
    local typ = type(obj)
    return typ == "table" and obj.__class or typ
  end

  local name, bases, clstb = ...

  if not bases or not bases[1] then
    bases = {Object} -- 默认继承 Object
  end

  -- 获取在名字中指定的命名空间
  local ns_name, name = name:match("^([^:]-):*([^:]+)$")
  ns_name = ns_name and (ns_name ~= '' and ns_name or 'class')

  local cls = {
    __classname = name;
    __ns_name   = ns_name;
    __class     = mcls;
    __new       = Object.__new; -- 这个方法比较常用
    __tostring  = Object.__tostring;
  }

  cls.__index = cls

  -- 复制所有成员到类中
  if clstb then
    for k, v in next, clstb do
      cls[k] = v
    end
  end

  -- 计算MRO
  local mro, err = mergeMROs(cls, bases)
  if err then _G.error(err, 3) end

  cls.__mro = mro
  setmetatable(cls, mcls)

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

  -- 注册类到对应的命名空间
  local ns = namespace.get(ns_name)
  ns[name] = cls

  return cls
end




-- 类创建器，用于处理语法
local function class(name, bases)
  return function(clstb, ...) -- 捕获成员表
    clstb = clstb or {}

    -- 如果获取到一个类
    if clstb.__classname then
      return class(name, {clstb, ...}) -- 捕获基类
    end

    local mcls = clstb.metaclass or luaclass -- 支持指定元类，默认 luaclass
    clstb.metaclass = nil

    return mcls(name, bases, clstb) -- 调用元类创建类
  end
end

return class