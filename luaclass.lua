-- 一些多次使用的常量
local SUPER_CLS = "__superclass" -- 标记超类的键
local CLS_OF_OBJ = "__class" -- 标记对象的类的键
local CLS_NAME = "__classname" -- 标记类名的键
local M_CLS_NAME = "luaclass" -- 本模块的类名
local META_INDEX = "__index" -- __index元方法
local META_TYPE = "__type" -- __type元方法
local META_TO_STR = "__tostring" -- __tostring元方法
local META_CALL = "__call" -- __call元方法
local META_META = "__metatable" -- __metatable元方法
local META_LIST = "__list" -- 预定义的__list方法
local META_INIT = "__init" -- 实例初始化方法
local NULL_TABLE = {} -- 一个空表


-- 用来获取环境变量，同时返回其在局部变量中的位置
local function getfenv(level)
  level = level and level +1 or 2
  local env_pos = debug.getinfo(level, "u").nparams + 1 -- _ENV的位置总是在固定参数后的第一个
  local _, env =debug.getlocal(level, env_pos)
  return env, env_pos
end



-- class的默认实例化行为
local function instantiate(cls, ...)

  local obj = setmetatable({ [CLS_OF_OBJ] = cls }, cls) -- 类是实例的元表（控制实例的行为），也会存入实例的__class属性中（便于访问）
  local init = cls[META_INIT]

  if type(init) == "function" then
    init(obj, ...) -- 实例化时调用__init元方法（如果有）
  end

  return obj
end



-- 在超类中查找属性和方法
local function lookupsuper(self, name)
  local super = rawget(self, SUPER_CLS)
  return super and super[name] -- 超类中不存在的，lua会自动在更上级的超类中查找
end



-- 在超类或对象的类中查找属性和方法
local function lookupall(self, name)
  local superattr = lookupsuper(self, name) -- 先尝试从超类中查找

  if superattr then
    return superattr
  end

  -- 如果没有则尝试从对象的类中查找
  local class = rawget(self, CLS_OF_OBJ)
  return class and (self == class and rawget(class, name) or class[name])
end



-- luaclass模块本身也是一个class，所有class都是luaclass的实例
local _M = {

  [CLS_NAME] = M_CLS_NAME,
  [META_INIT] = function(self, name, data, base) -- luaclass也有__init元方法，该方法是创建class的最原始方式
    if data then
      table.override(self, data) -- 用data的索引覆盖self的索引
    end

    if base then
      rawset(self, SUPER_CLS, base) -- 绑定指定的基本类（如果有）
    end

    -- 传递一些基本的元方法，这样需要访问时就不用在luaclass中查找了
    local luaclass = rawget(self, CLS_OF_OBJ)
    rawset(self, META_INDEX, lookupall)
    rawset(self, META_TYPE, rawget(luaclass, META_TYPE))
    rawset(self, META_TO_STR, rawget(luaclass, META_TO_STR))
    rawset(self, META_LIST, rawget(luaclass, META_LIST))
    rawset(self, CLS_NAME, rawget(self, CLS_NAME) or name)
    rawset(self, META_META, NULL_TABLE)
  end,

  [META_CALL] = instantiate, -- luaclass也遵从默认实例化行为，直接调用luaclass能动态创建一个class
  [META_INDEX] = lookupall, -- __index元方法用于在超类或对象的类中查找属性或方法，但并不绑定任何的类
  [META_META] = NULL_TABLE,

  [META_TYPE] = function (self) -- Androlua中或unifuncex模块中，type函数已被封装，支持__type元方法
    local class = rawget(self, CLS_OF_OBJ)
    return class and rawget(class, CLS_NAME) or "table"
  end,

  [META_TO_STR] = function(self) -- 对象被转换为字符串将得到类名
    return "class " .. rawget(rawget(self, CLS_OF_OBJ), CLS_NAME)
  end,

  -- 列出所有的属性和方法名
  [META_LIST] = function(cls_or_obj)
    local set = luaset or require "luaset" -- 导入集合模块
    if not set then error("Missing requirement 'luaset'.", 2) end --检查依赖
    local attr_set = set.of() -- 创建一个空的具体集合

:: continue_in_superclass ::

    for name in next, cls_or_obj do
      attr_set(name) -- 遍历所有属性和方法名并加入集合
    end

    local superclass = rawget(cls_or_obj, SUPER_CLS)
    if superclass then
      cls_or_obj = superclass
      goto continue_in_superclass -- 如果发现了超类，则继续在超类中遍历
    end

    return attr_set -- 返回包含所有属性和方法名的集合
  end
}


setmetatable(_M, _M) -- luaclass自己也是luaclass的实例



-- 面向用户创建一个class
function class(name_or_base)
  local old_env, env_pos = getfenv(2) -- 获取外界的_ENV

  -- 如果已经正在创建class，即第二次调用
  if rawget(old_env, CLS_NAME) then

    rawset(old_env, SUPER_CLS, name_or_base) -- 绑定指定的基本类（如果有）

    -- 把原来的_ENV返还给外界
    local original_env = rawget(getmetatable(old_env), META_INDEX)
    debug.setlocal(2, env_pos, original_env)

    -- 使创建的class成为luaclass的实例
    local cls_ins = setmetatable(old_env, _M)
    rawset(cls_ins, CLS_OF_OBJ, _M)
    _M.__init(cls_ins)

    return cls_ins -- class创建完毕
  end

  -- 如果没在创建class，即第一次调用
  local env = setmetatable({ [CLS_NAME] = name_or_base }, { [META_INDEX] = old_env }) -- 生成创建class环境，并暂存原来的_ENV
  debug.setlocal(2, env_pos, env) -- 将外界环境设置为创建class环境
end


-- 可能发生的错误信息
local ERR_NO_CLS = "Failed to find any class."
local ERR_NO_ME_1 = "No attribute or method \""
local ERR_NO_ME_2 = "\" existing in "
local ERR_NO_ME_3 = "'s superclass."


-- 构造一个专门用于拦截键的table
local interceptor = setmetatable(NULL_TABLE, {
  __index = function(self, name)

    local cls_or_obj = rawget(self, 1) -- 获取super函数传递的参数
    rawset(self, 1, nil) -- 销毁临时引用
printt(cls_or_obj)
    local subclass = rawget(cls_or_obj, CLS_NAME) and cls_or_obj or rawget(cls_or_obj, CLS_OF_OBJ) -- 获取子类
    local superitem = lookupsuper(subclass, name) -- 向上追溯直到找到超类属性或方法

    -- 如果查找不到，抛出一个错误
    if not superitem then
      error(ERR_NO_ME_1 .. name .. ERR_NO_ME_2 .. rawget(subclass, CLS_NAME) .. ERR_NO_ME_3, 2)
    end

    -- 如果找到一个方法
    if type(superitem) == "function" then
      return function(other, ...) -- 返回一个可从子类（或对象）的身份调用超类方法的闭包函数
        if other == interceptor then
          return superitem(cls_or_obj, ...)
        end
        return superitem(other, ...)
      end
    end

    return superitem -- 如果找到一个属性，直接返回
  end
})


-- 调用超类的属性或方法
function super(cls_or_obj)
  if not cls_or_obj then
    local _, self = debug.getlocal(2, 1) -- 如果没有传入类或者对象，则尝试从类方法中获取self（可能不是这个名字，但一定是第一个参数）
    cls_or_obj = self or error(ERR_NO_CLS, 2) -- 如果没有self，抛出一个错误
  end

  rawset(interceptor, 1, cls_or_obj) -- 把接收到的类或对象传给拦截器

  return interceptor -- 返回拦截器
end


return _M