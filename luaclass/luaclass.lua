--
-- Luaclass 纯lua的基于类OOP机制

local mergeMROs = require("luaclass.mergemros")
local namespace = require("luaclass.namespace")

local _G, type, next, rawget, rawset, setmetatable = _G, type, next, rawget, rawset, setmetatable

local function new_instance(cls, ...)
  local inst = cls:__new(...)
  local init = cls.__init
  if init then init(inst, ...) end
  return inst
end

local luaclass = {
  __classname  = "luaclass";
  __tostring   = function(self) return self.__classname end;
  __call       = new_instance;
} -- 基本元类

local Object   = {
  __classname  = "Object";
  __tostring   = function(self) return ("<%s object>"):format(self.__class.__classname) end;
  __new        = function(self) return setmetatable({__class = self}, self) end;
}   -- 根类

luaclass.__class = luaclass
Object.__class   = luaclass

luaclass.__mro   = {luaclass, Object, n=2, lv={1, 1, n=2}}
Object.__mro     = {Object, n=1, lv={1, n=1}}

setmetatable(luaclass, luaclass)
setmetatable(Object, luaclass)


-- 所有类的默认命名空间
-- 如果创建时不指定命名空间, 默认添加到这里
local class_NS = namespace.new("class", {
  luaclass = luaclass;
  Object   = Object;
})


-- 依据MRO查找属性和方法
local function lookup(self, name)
  local mro = self.__mro
  for i = 2, mro.n do
    local item = rawget(mro[i], name)
    if item then return item end
  end
end

luaclass.__index = lookup


local mm_names = {
  "__add", "__sub", "__mul", "__div", "__idiv", "__mod", "__pow",
  "__unm", "__band", "__bor", "__bxor", "__bnot", "__shl", "__shr",
  "__concat", "__len", "__eq", "__lt", "__le", "__call", "__gc"
}

-- 创建一个类
function luaclass.__new(mcls, name, bases, clstb)
  if not (bases or clstb) then -- 单参数调用时，返回对象的类
    local t = type(name)
    return t == "table" and name.__class or t
  end
  
  if not bases or not bases[1] then
   bases = {Object} -- 默认继承 Object
  end
  
  -- 获取在名字中指定的命名空间
  local ns_name, name = name:match("^([^:]-):*([^:]+)$")
  ns_name = ns_name and (ns_name ~= '' and ns_name or nil)
  local ns

  local cls = {
    __classname = name;
    __class     = mcls;
    __new       = Object.__new; -- 这个方法比较常用
    __tostring  = Object.__tostring;
  }
  
  cls.__index = cls

  -- 弹出 namespace 字段, 然后复制所有成员到类中
  if clstb then
    ns = namespace.get(clstb.namespace)
    local ns_name_ = ns and namespace.find(ns)
    clstb.namespace = nil
    
    -- 如果用两种方式指定了命名空间, 两次指定必须相同
    if ns_name_ then
      ns_name = (ns_name and ns_name1 ~= ns_name2 and
      _G.error(("specified namespaces dismatch in class '%s'")
        :format(name), 3))
                and ns_name or ns_name_
    end
    
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
  ns = ns or (ns_name
       and (namespace.get(ns_name)
       or namespace.new(ns_name)))
       or class_NS

  ns[name] = cls
  cls.__ns_name = ns_name or namespace.find(ns)
  
  return cls
end



-- 拦截并重定向成员访问
local interceptor = {
  __index = function(cache, k)
    local cls = cache[2] -- 访问者代表的子类
    local spueritem = lookup(cls, k) -- 寻找超类成员

    -- 如果查找不到，抛出一个错误
    if not spueritem then
      _G.error(("No attribute or method \"%s\" existing in %s's superclass."):format(k, cls.__classname), 2)
    end

    -- 如果找到一个方法，构造闭包
    if type(spueritem) == "function" then
      local function closure(obj, ...)
        if obj == cache then -- 重定向访问者
          return spueritem(cache[1], ...)
        end
        return spueritem(obj, ...)
      end
      cache[k] = closure -- 缓存这个闭包
      return closure
    end

    return superitem -- 如果找到一个属性，直接返回
  end
}


-- 缓存 super 调用结果
local callsupercache = setmetatable({}, {
  __mode = 'k', -- 弱键模式，对象销毁时清理缓存
  __index = function(self, obj)
    local cache = setmetatable({obj,
      rawget(obj, "__classname") and obj or obj.__class
    }, interceptor)
    self[obj] = cache
    return cache
  end
})


-- 以当前身份访问超类的属性或方法
local function super(obj)
  if not obj then
    local _, arg1 = _G.debug.getlocal(2, 1) -- 如果没有传入类或者对象，尝试获取函数第一参数
    obj = arg1 or _G.error("Failed to find any class.", 2) -- 如果没有，抛出一个错误
  end
  return callsupercache[obj]
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



local function isinstance(obj, cls)
  local t = type(obj)
  local obj_cls = t == "table" and obj.__class

  if not cls then
    return obj_cls or t -- 单参数时返回类型
  elseif not obj_cls then
    return t == cls -- 兼容 Lua 基本类型
  end

  local classes = obj_cls.__mro

  for i = 1, classes.n do
    if cls == classes[i] then
      return true
    end
  end

  return false
end



-- 导出组
luaclass.__export = {
  _G;
  luaclass   = luaclass;
  namespace  = namespace;
  class      = class;
  super      = super;
  isinstance = isinstance;
}


return luaclass