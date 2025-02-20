-- 用来获取环境变量，同时返回其在局部变量中的位置
local function getfenv(level)
  level = level and level +1 or 2
  local env_pos = debug.getinfo(level, "u").nparams + 1
  local _, env =debug.getlocal(level, env_pos)
  return env, env_pos
end



-- class的默认实例化行为
local function instantiate(cls, ...)

  local obj = setmetatable({}, cls) -- 类是实例的元表

  if type(cls.__init) == "function" then
    cls.__init(obj, ...) -- 实例化时调用__init元方法（如果有）
  end
  return obj
end



-- 在超类或对象的类中查找属性和方法
local function lookupsuper(self, name)
  if not rawget(self, "__classname") then
    return getmetatable(self)[name]
  end
  local super = rawget(self, "__superclass")
  return super and super[name]
end



-- luaclass模块本身也是一个class，所有class都是luaclass的实例
local _M = {

  __classname = "luaclass",

  __init = function(self, name, data, base) -- luaclass也有__init元方法，该方法是创建class的最原始方式
    local luaclass = getmetatable(self)

    if data then
      table.override(self, data)
    end

    if base then
      rawset(self, "__superclass", base) -- 绑定指定的基本类（如果有）
    end

    self.__index = luaclass.__index
    self.__type = luaclass.__type
    self.__tostring = luaclass.__tostring
    self.__list = luaclass.__list
    self.__classname = rawget(self, "__classname") or name

  end,

  __call = instantiate, -- luaclass也遵从默认实例化行为，直接调用luaclass能动态创建一个class

  __type = function (self) -- Androlua中或unifuncex模块中，type函数已被封装，支持__type元方法
    local meta = getmetatable(self)
    return meta.__index == lookupsuper and meta.__classname or "table"
  end,

  __index = lookupsuper, -- __index元方法用于在超类中查找属性或方法，但不直接绑定超类，方便后续更改__index的行为

  __tostring = function(self) -- class被转换为字符串将得到类名
    return "class " .. getmetatable(self).__classname
  end,
}


setmetatable(_M, _M) -- luaclass自己也是luaclass的实例



-- 列出所有的属性和方法名
function _M.__list(cls_or_obj)
  local set = luaset or require "luaset" -- 导入集合模块
  local attr_set = set.of() -- 创建一个空的具体集合

:: superclass ::

  for name in next, cls_or_obj do
    attr_set(name) -- 遍历所有属性和方法名并加入集合
  end

  if cls_or_obj.__superclass then
    cls_or_obj = cls_or_obj.__superclass
    goto superclass -- 如果发现了超类，则继续在超类中遍历
  end

  return attr_set -- 返回包含所有属性和方法名的集合
end



-- 面向用户创建一个class
function class(name_or_base)
  local old_env, env_pos = getfenv(2) -- 获取外界的_ENV

  -- 如果已经正在创建class，即第二次调用
  if rawget(old_env, "__classname") then

    rawset(old_env, "__superclass", name_or_base) -- 绑定指定的基本类（如果有）

    -- 把原来的_ENV返还给外界
    local original_env = rawget(getmetatable(old_env), "__index")
    debug.setlocal(2, env_pos, original_env)

    -- 使创建的class成为luaclass的实例
    local cls_ins = setmetatable(old_env, _M)
    _M.__init(cls_ins)

    return cls_ins -- class创建完毕
  end

  -- 如果没在创建class，即第一次调用
  local env = setmetatable({ __classname = name_or_base }, { __index = old_env }) -- 生成创建class环境，并暂存原来的_ENV
  debug.setlocal(2, env_pos, env) -- 将外界环境设置为创建class环境
end



-- 调用超类的属性或方法
function super(cls_or_obj)
  if not cls_or_obj then
    local _, self_cls = debug.getlocal(2, 1) -- 如果没有传入类或者对象，则尝试获取类方法第一个参数self
    cls_or_obj = self_cls or error("Failed to find any class.", 2) -- 如果没有self，抛出一个错误
  end

  -- 构造一个专门用于拦截键的table
  return setmetatable({}, {
    __index = function(self, name)

      -- 获取原来的子类
      local subclass = type(cls_or_obj) == "luaclass" and cls_or_obj or getmetatable(cls_or_obj)

      -- 获取目标的超类方法
      local superclass = rawget(subclass, "__superclass")
      local supermethod = superclass and (rawget(superclass, name) or error("No " .. name .. " method existing in " .. self.__classname .. "'s superclass.", 2)) or error("Error accessing superclass, for it maybe not existing or broken.", 2)

      -- 返回一个从子类（或对象）调用超类方法的闭包函数
      return function(...) return supermethod(cls_or_obj, ...) end
    end
  })
end


return _M