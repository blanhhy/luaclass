
local mergeMROs = require("luaclass.mergemros")
local namespace = require("luaclass.namespace")

local _G, type, next, rawget, rawset, setmetatable = _G, type, next, rawget, rawset, setmetatable

local _ENV = {}

-- 旧版环境机制兼容
if _G.tonumber(_G._VERSION:sub(-3)) < 5.2 then
  _G.setfenv(1, _ENV)
end

local weaktb = {__mode = 'v'}

-- 注册表：以命名空间+类名为索引，记录所有已知的类
local _Registry = setmetatable({}, {
  __mode = 'k',
  __index = function(self, ns) -- 自动创建新的引用空间
    local cache = setmetatable({}, weaktb)
    rawset(self, ns, cache)
    return cache
  end
})

-- 模块本身也是一个类，所有类都是luaclass的实例
local luaclass = _ENV

luaclass.__classname = "luaclass";
luaclass._Registry = _Registry;

function luaclass:__tostring()
  return self.__classname
end

-- luaclass自己也是自己的实例
luaclass.__class = luaclass
setmetatable(luaclass, luaclass)

_Registry[_G].luaclass = luaclass
luaclass.__mro = {luaclass, n = 1, lv = {1, n = 1}}


-- 计算MRO
local function compute_mro(cls, bases)
  if rawget(cls, "__mro") then return end -- 已经计算过MRO，直接返
  local mro, err = mergeMROs(cls, bases) -- 合并MRO
  if err then
    _G.error(err:format(cls), 3)
  end
  rawset(cls, "__mro", mro) -- 设置类的__mro属性
end



-- 依据MRO查找属性和方法
local function lookup(self, name)
  local mro = self.__mro
  for i = 2, mro.n do
    local item = rawget(mro[i], name)
    if item then return item end
  end
end

luaclass.__index = lookup


-- 一般对象字符串化（默认行为）
local function obj2str(self)
  return ("<%s object>"):format(self.__class.__classname)
end

-- 创建一般对象（默认行为）
local function object(cls)
  return setmetatable({ __class = cls }, cls)
end



local mm_name = {
  "__add", "__sub", "__mul", "__div", "__idiv", "__mod", "__pow",
  "__unm", "__band", "__bor", "__bxor", "__bnot", "__shl", "__shr",
  "__concat", "__len", "__eq", "__lt", "__le", "__call", "__gc"
}

-- 创建一个类
function luaclass.__new(mcls, name, bases, rtb)
  if not (bases or rtb) then -- 单参数调用时，返回对象的类
    local t = type(name)
    return t == "table" and name.__class or t
  end

  local cls = {
    __classname = name,
    __class = mcls,
    __new = object,
    __tostring = obj2str,
  }
  cls.__index = cls

  if rtb then
    local ns = rtb.namespace or _G
    ns[name] = cls -- 自动绑定和类名相同的变量名
    _Registry[ns][name] = cls
    rtb.namespace = nil
    for k, v in next, rtb do
      cls[k] = v
    end
  end

  setmetatable(cls, mcls) -- 绑定元类
  compute_mro(cls, bases) -- 计算MRO

  -- 由于 Lua 不从 __index 中查找元方法所以只好复制
  for i = 1, 21 do
    local name = mm_name[i]
    local mm = cls[name]
    if not rawget(cls, name) and mm then
      cls[name] = mm
    end
  end
  return cls
end


-- 实例化流程
function luaclass.__call(cls, ...)
  local inst = cls:__new(...)
  local init = cls.__init
  if init then init(inst, ...) end
  return inst
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
  return function(rtb, ...) -- 捕获原始表
    rtb = rtb or {}
    if rtb.__classname then
      return class(name, {rtb, ...}) -- 捕获基类
    end
    local meta = rtb.metaclass or luaclass -- 支持指定元类，默认 luaclass
    rtb.metatable = nil
    return meta(name, bases, rtb) -- 调用元类创建类
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
  _G,
  luaclass   = luaclass,
  class      = class,
  super      = super,
  isinstance = isinstance,
}


return luaclass