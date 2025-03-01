-- 一些多次使用的常量
local SUPER_CLS = "__superclass" -- 当前类的直接超类
local MRO = "__mro" -- 方法解析顺序
local CLS_FUNC = "class" -- class函数中的class
local CLS_OF_OBJ = "__class" -- 对象的类
local CLS_NAME = "__classname" -- 类名
local M_CLS_NAME = "luaclass" -- 本模块的类名
local META_INDEX = "__index" -- __index元方法
local META_TYPE = "__type" -- __type元方法
local META_TO_STR = "__tostring" -- __tostring元方法
local META_CALL = "__call" -- __call元方法
local META_META = "__metatable" -- __metatable元方法
local META_LIST = "__list" -- 预定义的__list方法
local META_INIT = "__init" -- 实例初始化方法
local NULL_TABLE = {} -- 一个空表
local TABLE_LEN = "n" -- 储存table长度的域


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
    return obj, init(obj, ...) -- 实例化时调用__init元方法（如果有）
  end

  return obj
end



-- 继承树线性化算法
local function linearization(inherit_tree)
  local branch_count = rawget(inherit_tree, TABLE_LEN) -- 获取分支数量
  local inherit_chain = {} -- 结果继承链
  local depth = 0 -- 合并分支后继承链的深度

  -- 遍历树的每一个分支
  for i = 1, branch_count do
    local branch = rawget(inherit_tree, i)

    -- 计算最的分支长度，作为合并后的深度
    local n = rawget(branch, TABLE_LEN)
    depth = n >= depth and n or depth

    -- 遍历当前分支的每一个超类层级
    for level, cur_supers in ipairs(branch) do

      local merged_cur_supers = rawget(inherit_chain, level) -- 在以后的分支中，直接从结果继承链中取出同层级的超类组
      or (function()
        local tmp = { [TABLE_LEN] = 0 } -- 当前为第一条分支，新建一个空的超类组，标记超类数量为0
        rawset(inherit_chain, level, tmp) -- 加到结果继承链的同层级区域中
        return tmp
      end)()

      local merged_cur_supers_count = rawget(merged_cur_supers, TABLE_LEN) -- 获取目前已经完成合并的超类数量

      local add_count = 0
      for _, cur_super in ipairs(cur_supers) do
        if not rawget(merged_cur_supers, cur_super) then
          table.insert(merged_cur_supers, cur_super)
          rawset(merged_cur_supers, cur_super, true)
          add_count = add_count + 1 -- 计算实际被合并的超类数量
        end
      end

      rawset(merged_cur_supers, TABLE_LEN, merged_cur_supers_count + add_count) -- 更新已经完成合并的超类数量
    end
  end

  rawset(inherit_chain, TABLE_LEN, depth) -- 设置结果继承链深度
  return inherit_chain
end



-- 创建类时计算继承链
function compute_inherit_chain(cls, ...)
local branch_count = select("#", ...)
  if branch_count ~= 0 then
    local inherit_tree = { [TABLE_LEN] = branch_count } -- 有多少个直接超类，就有多少个分支
    for i = 1, branch_count do
      local cur_direct_super = select(i, ...) -- 获取...中的第i个超类
      local cur_upper_inherit_chain = table.override({}, rawget(cur_direct_super, SUPER_CLS) or { [TABLE_LEN] = 0 })
      table.insert(cur_upper_inherit_chain, 1, { cur_direct_super , [TABLE_LEN] = 1 })
      rawset(cur_upper_inherit_chain,TABLE_LEN, rawget(cur_upper_inherit_chain, TABLE_LEN) + 1)
      rawset(inherit_tree, i, cur_upper_inherit_chain)
    end
    rawset(cls, SUPER_CLS, linearization(inherit_tree))
  end
end


-- 计算MRO
local function compute_mro(cls)
  local mro = rawget(cls, "__mro")

  -- 如果已经计算过MRO，直接返回
  if mro then
    return mro
  end

  mro = {}

  -- 获取继承链
  local inherit_chain = rawget(cls, SUPER_CLS)
  if not inherit_chain then
    rawset(cls, MRO, mro)
    return mro -- 如果没有继承链，直接输出空的MRO
  end

  local seen = {} -- 记录已经出现过的超类
  local depth = rawget(inherit_chain, TABLE_LEN)

  -- 由深至浅地遍历超类组，确保出现在多个层级中的超类只计最深的位置
  for i = depth, 1, -1 do
    local cur_supers = rawget(inherit_chain, i)
    local cur_supers_count = rawget(cur_supers, TABLE_LEN)
    -- 从后往前遍历同层超类，确保下级声明顺序靠后的超类的超类后被考虑
    for j = cur_supers_count, 1, -1 do
      local cur_super = rawget(cur_supers, j)

      if not rawget(seen, cur_super) then
        table.insert(mro, 1, cur_super)
        rawset(seen, cur_super, true)
      end
    end
  end
  rawset(cls, MRO, mro)

  return mro
end

-- 依据MRO查找属性和方法
local function lookupsuper(self, name)
  local mro = compute_mro(self) -- 获取类的MRO
  for _, class in ipairs(mro) do
    local item = rawget(class, name)
    if item then
      return item
    end
  end
  return nil
end


-- 在超类或对象的类中查找属性和方法
local function lookupall(self, name)
  local superitem = lookupsuper(self, name) -- 先尝试从超类中查找

  if superitem then
    return superitem
  end

  -- 如果没有则尝试从对象的类中查找
  local class = rawget(self, CLS_OF_OBJ)
  return class and (self == class and rawget(class, name) or class[name])
end



-- luaclass模块本身也是一个class，所有class都是luaclass的实例
local _M = {

  [CLS_NAME] = M_CLS_NAME,
  [META_INIT] = function(self, name, data, ...) -- luaclass也有__init元方法，该方法是创建class的最原始方式
    if data then
      table.override(self, data) -- 用data的索引覆盖self的索引
    end

    -- 储存继承链（如果有）
    compute_inherit_chain(self, ...)

    compute_mro(self) -- 储存MRO

    -- 传递一些基本的元方法，这样需要访问时就不用在luaclass中查找了
    local luaclass = rawget(self, CLS_OF_OBJ)
    rawset(self, META_INDEX, lookupall)
    rawset(self, META_TYPE, rawget(luaclass, META_TYPE))
    rawset(self, META_TO_STR, rawget(self, META_TO_STR) or rawget(luaclass, META_TO_STR))
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
    return (rawget(self, CLS_NAME) or "instance") .. " of class " .. rawget(rawget(self, CLS_OF_OBJ), CLS_NAME)
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
local function classstart(self, name, ...)
  local old_env, env_pos = getfenv(2) -- 获取外界的_ENV

  -- 生成创建class环境，并暂存原来的_ENV
  local cls_env = setmetatable({ [CLS_NAME] = name }, { [META_INDEX] = old_env })
  rawset(old_env, 1, old_env)

  -- 储存继承链（如果有）
  compute_inherit_chain(cls_env, ...)

  compute_mro(cls_env) -- 储存MRO

  debug.setlocal(2, env_pos, cls_env) -- 将外界环境设置为创建class环境
  return cls_env
end


-- 结束创建class环境
local function classend()
  local cls_env, env_pos = getfenv(2) -- 获取class

  -- 把原来的_ENV返还给外界
  local old_env = table.remove(cls_env, 1)
  debug.setlocal(2, env_pos, old_env)

  -- 如果创建class时没有用local修饰，则将变量保存在_ENV中
  local cls_name = rawget(cls_env, CLS_NAME)
  local cls_self = rawget(cls_env, cls_name)
  if cls_self then
    rawset(old_env, cls_name, cls_self)
    rawset(cls_env, cls_name, nil)
  end

  -- 使创建的class成为luaclass的实例
  setmetatable(cls_env, _M)
  rawset(cls_env, CLS_OF_OBJ, _M)
  _M.__init(cls_env)
end


-- 可能发生的错误信息
local ERR_NO_CLS = "Failed to find any class."
local ERR_NO_ME_1 = "No attribute or method \""
local ERR_NO_ME_2 = "\" existing in "
local ERR_NO_ME_3 = "'s superclass."


-- 构造一个专门用于拦截键的table
local callsupercache = {}
local interceptor = setmetatable(callsupercache, {
  __index = function(self, name)

    local cls_or_obj = rawget(self, 1) -- 获取super函数传递的参数
    rawset(self, 1, nil) -- 销毁临时引用

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
local function callsuper(cls_or_obj)
  if not cls_or_obj then
    local _, self = debug.getlocal(2, 1) -- 如果没有传入类或者对象，则尝试从类方法中获取self（可能不是这个名字，但一定是第一个参数）
    cls_or_obj = self or error(ERR_NO_CLS, 2) -- 如果没有self，抛出一个错误
  end

  rawset(interceptor, 1, cls_or_obj) -- 把接收到的类或对象传给拦截器

  return interceptor -- 返回拦截器
end


-- 导出两个全局函数
class = setmetatable({
  ["end"] = classend,
},{
  [META_CALL] = classstart,
})


super = callsuper


return _M