local _G = _G
local rawget = _G.rawget
local rawset = _G.rawset
local type = _G.type
local next = _G.next
local getmetatable = _G.getmetatable
local setmetatable = _G.setmetatable



-- 注册表：以命名空间+类名为索引，记录所有已知的类
local weaktb = {__mode = "kv"}
local _Registry = setmetatable({}, {
  __mode = "k",
  __index = function(self, ns) -- 自动创建新的引用空间
    local cache = setmetatable({}, weaktb)
    rawset(self, ns, cache)
    return cache
  end
})


-- 计算MRO
local function compute_mro(cls, bases)
  local mro = rawget(cls, "__mro")

  -- 如果已经计算过MRO，直接返回
  if mro then
    return mro
  end

  mro = {cls} -- 初始化MRO，仅包含自身
  local mro_len = 1
  local mro_lv = { 1, n = 1 } -- 初始化分块信息

  -- 获取直接继承的超类
  if not bases then
    mro.n = mro_len
    mro.lv = mro_lv
    rawset(cls, "__mro", mro)
    return mro -- 如果没有超类，直接返回初始的MRO
  end

  -- 分块线性化算法
  local branches_count = #bases -- 有多少个直接超类，就有多少个分支
  local mros = {} -- 继承树平铺场地
  local branch_lens = {} -- 每一个分支的长度
  local mro_lvs = {} -- 每一个分支中的分块信息
  local progresses = {} -- 分支处理进度，兼去重表
  local peak_level = 1 -- 层顶位置，即层级最多的分支的层级数
  local order = 0 -- 维持单调性原则

  -- ①首先将继承树平铺，按分支与超类层级分为若干个小块
  for branch_i = 1, branches_count do
    local superclass = bases[branch_i]

    -- 获取上一级MRO
    local upper_mro = rawget(superclass, "__mro")
    mros[branch_i] = upper_mro

    branch_lens[branch_i] = upper_mro.n -- 记录分支长度
    progresses[branch_i] = 1 -- 初始化处理进度

    -- 收集每个分支的分块信息
    -- 分块信息，就是每一个继承层级中的超类数量，按由浅到深的顺序左右排列
    local upper_mro_lv = upper_mro.lv
    mro_lvs[branch_i] = upper_mro_lv

    -- 计算最大的层级数
    local upper_mro_lv_count = upper_mro_lv.n
    peak_level = upper_mro_lv_count >= peak_level and upper_mro_lv_count or peak_level
  end

  -- ②想象有一个指针，从上往下、从前往后依次扫过所有区块，得到的顺序即为继承链
  for Ptr_level = 1, peak_level do
    local merged_in_level = 0 -- 记录当前层级中合并的超类数量，包含所有分支

    for Ptr_branch = 1, branches_count do
      local branch = mros[Ptr_branch]

      -- 当前区块体积，也就是划分到这个区块的超类组（假设有）中的的类数量
      local block_volume = mro_lvs[Ptr_branch][Ptr_level]

      -- 如果这个区块上有超类组
      if block_volume then
        local branch_len = branch_lens[Ptr_branch] -- 当前分支的长度
        local progress = progresses[Ptr_branch] -- 当前分支处理进度
        local progress_updated = progress + block_volume -- 这个区块处理后的进度

        -- 从前往后扫描这个区块，采集其中的类
        for i = progress, progress_updated -1 do
          local Ptr_cls = mros[Ptr_branch][i] -- 指针当前指向的类
          local seen_pos = progresses[Ptr_cls]
          if not seen_pos then -- 如果当前类没出现过
            local pos = mro_len + 1
            mro[pos] = Ptr_cls -- 那么加入结果MRO中
            progresses[Ptr_cls] = pos -- 记录已经出现过的类
            merged_in_level = merged_in_level + 1 -- 计算当前层级合并的超类数量，作为结果MRO的分块信息缓存
            mro_len = mro_len + 1
           else
            -- 如果后检测到重复的超类比前面重复的超类出现位置更早，表明本次继承违反了单调性原则
            order = seen_pos >= order and seen_pos or _G.error((function()
              local clsname = rawget(cls, "__classname") or "<UnnamedClass>" -- 当前类名
              local mro_path = (function()
                local str_list = {}
                for i = 1, #mro do
                  str_list[i] = _G.tostring(mro[i])
                end
                return _G.table.concat(str_list, " -> ")
              end)() -- MRO 路径
              local seen_cls_name = rawget(mro[order], "__classname") or "<UnnamedClass>" -- 已知的类名
              local conflict_cls_name = rawget(Ptr_cls, "__classname") or "<UnnamedClass>" -- 冲突的类名
              local branch_name = rawget(bases[Ptr_branch], "__classname") -- 当前分支类名
              return
              ("Cannot create class '%s' due to MRO conflict. (in bases: %s, %s)\nProcessing traceback: %s ... %s@%d -> %s@%d (in branch '%s', level #%s)")
              :format(clsname, seen_cls_name, conflict_cls_name, mro_path, seen_cls_name, order, conflict_cls_name, seen_pos, branch_name, Ptr_level)
            end)(), 4) -- 拒绝创建类，并抛出错误提示无法创建的类和发生冲突的类
          end
        end
        rawset(progresses, Ptr_branch, progress_updated) -- 更新处理进度
      end
    end

    rawset(mro_lv, Ptr_level + 1, merged_in_level) -- 缓存顺便收集的结果MRO分块信息，以便于下一次合并
  end

  mro_lv.n = peak_level + 1 -- 每继承一次，继承链多一层
  mro.n = mro_len -- 缓存继承链长度
  mro.lv = mro_lv -- 缓存分区信息
  rawset(cls, "__mro", mro) -- 设置类的__mro属性
  return mro
end




-- 依据MRO查找属性和方法
local function lookup(self, name, start)
  local mro = compute_mro(self)
  for i = start, mro.n do
    local item = rawget(mro[i], name)
    if item then return item end
  end
end


-- 从超类或对象的类中查找属性和方法
local function index_lookup(self, name)
  if rawget(self, "__classname") then
    return lookup(self, name, 2)
  end
  local cls = rawget(self, "__class")
  return cls and lookup(cls, name, 1)
end


-- 类和对象默认的字符串化行为
local function str(self)
  return rawget(self, "__classname") or ("<%s object>"):format(rawget(self.__class, "__classname"))
end


-- 创建一般对象（默认行为）
local function object(cls)
  return setmetatable({ __class = cls }, cls)
end


-- 所有类（包括元类）的默认实例化流程
local function instantiate(cls, ...)
  local obj = cls:__new(...) -- 调用 __new 方法创建对象

  -- 然后调用 __init 方法（如果有）初始化
  local init = cls.__init
  if init then init(obj, ...) end

  return obj -- 返回实例对象
end


-- 创建一个类
local function luaclass(mcls, name, bases, rtb)
  if not (bases or rtb) then -- 单参数调用时，返回对象的类
    local t = type(name)
    if t == "table" then
      return name.__class or t
    end
    return t
  end

  local cls = {
    __classname = name,
    __class = mcls,
    __new = object,
    __index = index_lookup,
    __call = instantiate,
    __tostring = str,
  }

  if rtb then
    _Registry[rtb.env or _G][name] = cls
    rtb.env = nil
    for k, v in next, rtb do
      cls[k] = v
    end
  end

  setmetatable(cls, mcls) -- 绑定元类
  compute_mro(cls, bases) -- 计算MRO
  return cls
end



-- luaclass模块本身也是一个class，所有类都是luaclass的实例
local _M = {
  __classname = "luaclass",
  __new = luaclass,
  __call = instantiate,
  __index = index_lookup,
  __tostring = str,
  _Registry = _Registry,
}
_M.__class = _M
_M__mro = { _M, n = 1, lv = { 1, n = 1 }}
setmetatable(_M, _M) -- luaclass自己也是自己的实例
_Registry[_G].luaclass = _M




-- 拦截并重定向成员访问
local interceptor = {
  __index = function(cache, k)
    local sub = cache[2] -- 访问者代表的子类
    local item = lookup(sub, k, 2) -- 寻找超类成员

    -- 如果查找不到，抛出一个错误
    if not item then
      _G.error(("No attribute or method \"%s\" existing in %s's superclass."):format(k, sub.__classname), 2)
    end

    -- 如果找到一个方法，构造闭包
    if type(item) == "function" then
      local function closure(obj, ...)
        if obj == cache then -- 重定向访问者
          return item(cache[1], ...)
        end
        return item(obj, ...)
      end
      cache[k] = closure -- 缓存这个闭包
      return closure
    end

    return item -- 如果找到一个属性，直接返回
  end
}


-- 缓存 super 调用结果
local callsupercache = setmetatable({}, {
  __mode = "k", -- 弱键模式，对象销毁时清理缓存
  __index = function(self, obj)
    local cache = setmetatable({obj,
      rawget(obj, "__classname") and obj or obj.__class -- 获取子类
    }, interceptor)
    self[obj] = cache
    return cache
  end,
})


-- 以当前身份访问超类的属性或方法
local function super(obj)
  if not obj then
    local _, arg1 = _G.debug.getlocal(2, 1) -- 如果没有传入类或者对象，尝试获取函数第一参数
    obj = arg1 or _G.error("Failed to find any class.", 2) -- 如果没有，抛出一个错误
  end
  return callsupercache[obj]
end




-- 类创建器，仅处理语法
local function class_creater(name, bases)
  return function(rtb, ...) -- 捕获原始表
    rtb = rtb or {}
    if not rtb.__classname then
      local env = rtb.env or _G -- 支持指定命名空间，默认 _G
      local meta = rtb.metaclass or _M -- 支持指定元类，默认 luaclass
      rtb.metatable = nil
      local cls = meta(name, bases, rtb) -- 调用元类创建类
      env[name] = cls -- 自动绑定和类名相同的变量名
      return cls -- 顺便返回这个类
    end
    return class_creater(name, {rtb, ...}) -- 捕获基类
  end
end



local function isinstance(obj, cls)
  local t = type(obj)
  local obj_cls = t == "table" and obj.__class

  if not cls then
    return obj_cls or t
   elseif not obj_cls then
    return t == cls
  end

  local classes = obj_cls.__mro
  for i = 1, classes.n do
    if cls == classes[i] then
      return true
    end
  end

  return false
end


-- 导出三个全局函数
_M.__export = {
  _G,
  luaclass = _M,
  class = class_creater,
  super = super,
  isinstance = isinstance,
}


return _M