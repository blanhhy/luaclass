-- 一些多次使用的常量
local SUPER_CLS = "__superclass" -- 当前类的直接超类
local MRO = "__mro" -- 方法解析顺序
local CLS_OF_OBJ = "__class" -- 对象的类
local CLS_NAME = "__classname" -- 类名
local META_INDEX = "__index" -- __index元方法
local META_TYPE = "__type" -- __type元方法
local META_TO_STR = "__tostring" -- __tostring元方法
local META_CALL = "__call" -- __call元方法
local META_META = "__metatable" -- __metatable元方法
-- local META_LIST = "__list" -- 预定义的__list方法（暂时废弃，待以后写出缓存机制会重新加入）
local META_INIT = "__init" -- 实例初始化方法
local NULL_TABLE = {} -- 一个空表
local TABLE_LEN = "n" -- 储存table长度的域
local MRO_LV = "lv" -- MRO中储存分块信息的域




-- 计算MRO
local function compute_mro(cls)
  local mro = rawget(cls, MRO)

  -- 如果已经计算过MRO，直接返回
  if mro then
    return mro
  end

  mro = { cls } -- 初始化MRO，仅包含自身
  local mro_len = 1
  local mro_lv = { 1, [TABLE_LEN] = 1 } -- 初始化分块信息

  -- 获取直接继承的超类
  local superclasses = rawget(cls, SUPER_CLS)
  if not superclasses then
    rawset(mro, TABLE_LEN, mro_len)
    rawset(mro, MRO_LV, mro_lv)
    rawset(cls, MRO, mro)
    return mro -- 如果没有超类，直接返回初始的MRO
  end

  -- 分块线性化算法
  local branches_count = rawget(superclasses, TABLE_LEN) -- 有多少个直接超类，就有多少个分支
  local mros = {} -- 继承树平铺场地
  local branch_lens = {} -- 每一个分支的长度
  local mro_lvs = {} -- 每一个分支中的分块信息
  local peak_level = 1 -- 层顶位置，即层级最多的分支的层级数
  local progresses = {} -- 分支处理进度，兼去重表
  local order = 0 -- 维持单调性原则

  -- ①首先将继承树平铺，按分支与超类层级分为若干个小块
  for branch_i = 1, branches_count do
    local superclass = rawget(superclasses, branch_i)

    -- 获取上一级MRO
    local upper_mro = rawget(superclass, MRO)
    rawset(mros, branch_i, upper_mro)

    -- 记录分支长度
    rawset(branch_lens, branch_i, rawget(upper_mro, TABLE_LEN))
    
    rawset(progresses, branch_i, 1) -- 初始化处理进度

    -- 收集每个分支的分块信息
    -- 分块信息，就是每一个继承层级中的超类数量，按由浅到深的顺序左右排列
    local upper_mro_lv = rawget(upper_mro, MRO_LV)
    rawset(mro_lvs, branch_i, upper_mro_lv)

    -- 计算最大的层级数
    local upper_mro_lv_count = rawget(upper_mro_lv, TABLE_LEN)
    peak_level = upper_mro_lv_count >= peak_level and upper_mro_lv_count or peak_level
  end

  -- ②想象有一个指针，从上往下、从前往后依次扫过所有区块，得到的顺序即为继承链
  for Ptr_level = 1, peak_level do
    local merged_in_level = 0 -- 记录当前层级中合并的超类数量，包含所有分支

    for Ptr_branch = 1, branches_count do
      local branch = rawget(mros, Ptr_branch)

      -- 当前区块体积，也就是划分到这个区块的超类组（假设有）中的的类数量
      local block_volume = rawget(rawget(mro_lvs, Ptr_branch), Ptr_level)

      -- 如果这个区块上有超类组
      if block_volume then
        local branch_len = rawget(branch_lens, Ptr_branch) -- 当前分支的长度
        local progress = rawget(progresses, Ptr_branch) -- 当前分支处理进度
        local progress_updated = progress + block_volume -- 这个区块处理后的进度

        -- 从前往后扫描这个区块，采集其中的类
        for i = progress, progress_updated -1 do
          local Ptr_cls = rawget(rawget(mros, Ptr_branch), i) -- 指针当前指向的类
          local seen_pos = rawget(progresses, Ptr_cls) 
          if not seen_pos then -- 如果当前类没出现过
            local pos = mro_len + 1
            rawset(mro, pos, Ptr_cls) -- 那么加入结果MRO中
            rawset(progresses, Ptr_cls, pos) -- 记录已经出现过的类
            merged_in_level = merged_in_level + 1 -- 计算当前层级合并的超类数量，作为结果MRO的分块信息缓存
            mro_len = mro_len + 1
           else
            -- 如果后检测到重复的超类比前面重复的超类出现位置更早，表明本次继承违反了单调性原则
            order = seen_pos >= order and seen_pos or error((function()
              local clsname = rawget(cls, CLS_NAME) or "<UnnamedClass>" -- 当前类名
              local mro_path = table.tostring(mro, " -> ") -- MRO 路径
              local seen_cls_name = rawget(mro[order], CLS_NAME) or "<UnnamedClass>" -- 已知的类名
              local conflict_cls_name = rawget(Ptr_cls, CLS_NAME) or "<UnnamedClass>" -- 冲突的类名
              local branch_name = rawget(superclasses[Ptr_branch], CLS_NAME) -- 当前分支类名
              return string.format(
              "Cannot create class '%s' due to MRO conflict. (in bases: %s, %s)\nProcessing traceback: %s ... %s@%d -> %s@%d (in branch '%s', level #%s)",
              clsname, seen_cls_name, conflict_cls_name, mro_path, seen_cls_name, order, conflict_cls_name, seen_pos, branch_name, Ptr_level)
            end)(), 4) -- 拒绝创建类，并抛出错误提示无法创建的类和发生冲突的类
          end
        end
        rawset(progresses, Ptr_branch, progress_updated) -- 更新处理进度
      end
    end

    rawset(mro_lv, Ptr_level + 1, merged_in_level) -- 缓存顺便收集的结果MRO分块信息，以便于下一次合并
  end

  rawset(mro_lv, TABLE_LEN, peak_level + 1) -- 每继承一次，继承链多一层
  rawset(mro, TABLE_LEN, mro_len) -- 缓存继承链长度
  rawset(mro, MRO_LV, mro_lv) -- 缓存分区信息
  rawset(cls, MRO, mro) -- 设置类的__mro属性
  return mro
end




-- 依据MRO查找属性和方法
local function lookup(self, name, start)
  local mro = compute_mro(self)
  local mro_len = rawget(mro, TABLE_LEN)
  for i = start, mro_len do
    local item = rawget(rawget(mro, i), name)
    if item then return item end
  end
end


-- 从超类或对象的类中查找属性和方法
local function lookupall(self, name)
  if rawget(self, SUPER_CLS) then
    return lookup(self, name, 2)
  end
  local cls = rawget(self, CLS_OF_OBJ)
  if cls then
    return lookup(cls, name, 1)
  end
end



-- __type元方法
local function __type(self)
  local class = rawget(self, CLS_OF_OBJ)
  return class and rawget(class, CLS_NAME) or "table"
end

-- 类和对象默认的字符串化行为
local function default_tostring(self)
  return rawget(self, CLS_NAME) or "instance of class " .. rawget(rawget(self, CLS_OF_OBJ), CLS_NAME)
end



-- 所有类的默认实例化行为
local function instantiate(cls, ...)

  local obj = setmetatable({ [CLS_OF_OBJ] = cls }, cls) -- 类是实例的元表（控制实例的行为），也会存入实例的__class属性中（便于访问）
  local init = cls[META_INIT]

  if type(init) == "function" then
    return obj, init(obj, ...) -- 实例化时调用__init方法（如果有）
  end

  return obj
end



-- 默认的创建类行为
local function luaclass(self, name, data, ...)
  local _tp = type(name)
  if _tp ~= "string" then -- 如果类名不是字符串，拒绝创建类
    return _tp
  end

  rawset(self, CLS_NAME, rawget(self, CLS_NAME) or name) -- 设置类名

  if data then
    table.override(self, data) -- 用data中的值简单覆盖self
  end

  -- 绑定超类组（如果有）
  if ... then
    local superclasses = rawget(..., CLS_NAME) and {...} or ...
    rawset(superclasses, TABLE_LEN, #superclasses)
    rawset(self, SUPER_CLS, superclasses)
  end

  compute_mro(self) -- 储存MRO

  -- 传递一些基本的元方法，这样需要访问时就不用在luaclass中查找了
  rawset(self, META_INDEX, lookupall)
  rawset(self, META_TYPE, __type)
  rawset(self, META_TO_STR, rawget(self, META_TO_STR) or default_tostring)
  rawset(self, META_META, NULL_TABLE)

  return self
end



-- luaclass模块本身也是一个class，所有类都是luaclass的实例
local _M = {
  [CLS_NAME] = "luaclass",
  [META_META] = NULL_TABLE,
  [META_INIT] = luaclass,
  [META_CALL] = instantiate,
  [META_INDEX] = lookupall,
  [META_TYPE] = __type,
  [META_TO_STR] = default_tostring,
} -- 这里也清晰地展现了一个类的基本结构

-- 尽管所有类都已经是luaclass的实例了，但若有类想要继承luaclass，也是允许的
_M[MRO] = { _M, [TABLE_LEN] = 1, [MRO_LV] = { 1, [TABLE_LEN] = 1 }}
setmetatable(_M, _M) -- luaclass自己也是luaclass的实例




-- 构造一个用于拦截方法调用以及缓存super调用结果的table
local callsupercache = {}
local interceptor = setmetatable(callsupercache, {
  __mode = "k", -- 弱引用键模式，以便对象销毁时自动清除缓存
  __index = function(self, name)

    local cls_or_obj = rawget(self, 1) -- 获取super函数传递的参数
    rawset(self, 1, nil) -- 销毁临时引用

    -- 如果同样的方法调用行为已经被缓存，则返回缓存，不再查找
    local cache_of_this = rawget(self, cls_or_obj)
    local action = cache_of_this and cache_of_this[name]
    if action then return action end

    local subclass = rawget(cls_or_obj, CLS_NAME) and cls_or_obj or rawget(cls_or_obj, CLS_OF_OBJ) -- 获取子类
    local superitem = lookup(subclass, name, 2) -- 向上追溯直到找到超类属性或方法

    -- 如果查找不到，抛出一个错误
    if not superitem then
      error(string.format("No attribute or method \"%s\" existing in %s's superclass.", name, rawget(subclass, CLS_NAME)), 2)
    end

    -- 为当前对象创建一个缓存空间
    if not cache_of_this then
      cache_of_this = {}
      rawset(self, cls_or_obj, cache_of_this)
    end

    -- 如果找到一个方法
    if type(superitem) == "function" then
      -- 返回一个可从子类（或对象）的身份调用超类方法的闭包函数
      local function closure(other, ...)
        if other == callsupercache then
          return superitem(cls_or_obj, ...)
        end
        return superitem(other, ...)
      end
      cache_of_this[name] = closure -- 缓存这个闭包
      return closure
    end

    return superitem -- 如果找到一个属性，直接返回
  end
})


-- 调用超类的属性或方法
local function callsuper(cls_or_obj)
  if not cls_or_obj then
    local _, self = debug.getlocal(2, 1) -- 如果没有传入类或者对象，则尝试从类方法中获取self（可能不是这个名字，但一定是第一个参数）
    cls_or_obj = self or error("Failed to find any class.", 2) -- 如果没有self，抛出一个错误
  end
  rawset(interceptor, 1, cls_or_obj) -- 把接收到的类或对象传给拦截器
  return interceptor -- 返回拦截器对象
end



-- 类创建器，但并不处理类创建逻辑，只是对luaclass的简单封装
local function class_creater(self, classname)
  return function(...)
    local data = ... or {}

    -- 如果传入的是类的原表，直接创建类
    if not rawget(data, CLS_NAME) then
      data = setmetatable(data, _M) -- 使类成为luaclass的实例
      rawset(data, CLS_OF_OBJ, _M)
      local cls = luaclass(data, classname) -- 调用luaclass实例化方法初始化类
      _ENV[classname] = cls -- 创建的类自动绑定和类名相同的环境变量名
      return cls -- 返回这个类，用户可以创建别名
    end

    -- 否则，如果传入类，则先考虑继承，再接收原表
    local superclasses = {...}
    return function(data)
      data = setmetatable(data or {}, _M)
      rawset(data, CLS_OF_OBJ, _M)
      local cls = luaclass(data, classname, nil, superclasses)
      _ENV[classname] = cls
      return cls
    end
  end
end


-- 导出三个全局函数
class = setmetatable(NULL_TABLE, {
  [META_INDEX] = class_creater,
  [META_CALL] = class_creater,
})

super = callsuper


function isinstance(obj, cls)
  if not cls return rawget(obj, CLS_OF_OBJ) end

  local _rawtype = rawtype(obj)
  local obj_cls = _rawtype == "table" and rawget(obj, CLS_OF_OBJ)
  if not obj_cls then
    if type(obj) == cls then return true end
    return false
  end

  local obj_classes = rawget(obj_cls, MRO)
  for i = 1, obj_classes.n do
    if cls == obj_classes[i] then
      return true
    end
  end

  return type(obj) == cls
end


return _M