-- 
-- 命名空间管理器


local _G = _G -- Lua 的全局命名空间
local type, next, rawset, getmetatable, setmetatable = _G.type, _G.next, _G.rawset, _G.getmetatable, _G.setmetatable

local namespace = {_G = _G}     -- 根命名空间容器
local spacename = {[_G] = "_G"} -- 命名空间名称映射
local protected = {_G = true}   -- 禁止删除的命名空间


-- 尝试注册一些 Lua 标准库
local function prequire(name)
  local ok, lib = pcall(require, name)
  if ok then
    namespace[name] = lib
    spacename[lib]  = name
  end
  return lib
end

prequire("string")
prequire("table")
prequire("math")
prequire("io")
prequire("os")
prequire("debug")
prequire("coroutine")
prequire("package")
prequire("bit32")
prequire("utf8")
prequire("ffi")
prequire("jit")



-- 辅助函数：检查合法标识符
local invalid_char = (load or loadstring)("local 〇=0") -- 取决于解释器的实际实现
  and "[^%w_\128-\244]" or "[^%w_]" -- 非法字符正则表达式

local keywords = {
  "and", "break", "do", "else", "elseif", "end", "false", "for",
  "function", "goto", "if", "in", "local", "nil", "not", "or",
  "repeat", "return", "then", "true", "until", "while"
} -- Lua 关键字

local function check_identifier(str)
  if str == '' then
    return false
  end

  -- 检查是否包含非法字符
  if str:match(invalid_char) then
    return false
  end

  -- 检查首字符是否为数字
  if str:match("^%d") then
    return false
  end

  -- 检查是否为关键字
  for i = 1, #keywords do
    if str == keywords[i] then
      return false
    end
  end

  return true
end



local function using_factory(portal, mt)
  local list = portal["$list"]
  
  return function(ns)
    ns = ns and (namespace[ns]or(spacename[ns]and(ns)or(nil)))
    if not ns then error("using nothing!", 2) end
    
    list.n        = list.n + 1
    list[list.n]  = ns
    mt.__newindex = list[1]
    
    return portal
  end
end

-- 在提供主命名空间之前, 不可以定义变量
local function disallow(_, name)
  error(("definition of variable '%s' in namespace ot allowed, namespace not set")
    :format(name), 2)
end

local function ns_get_val(portal, name)
  local value
  local ns_list = portal["$list"]
  for i = 1, ns_list.n do
    value = ns_list[i][name]
    if nil ~= value then
      return value
    end
  end
end


-- 使用命名空间, 返回一个用作 _ENV 的表
local function ns_use(ns)
  
  local ns_list   = {n=0} -- 要使用的命名空间列表
  local ns_portal = {     -- 命名空间访问入口
	["$list"]  = ns_list;
  }
  local ns_MT     = {     -- 命名空间入口的元表
	__index       = ns_get_val;
	__newindex    = disallow;
  }
  
  ns_portal.using = using_factory(ns_portal, ns_MT);
  
  -- 如果提供了主命名空间, 立即使用它
  -- 也可以稍后再提供, 但这期间不可以定义变量
  if ns then
	ns_portal.using(ns)
  end
  
  return setmetatable(ns_portal, ns_MT)
end


-- 创建命名空间
local function ns_new(ns_name, ns)

  -- 基础格式校验, 排除各个环节出现的的空字符串
  if  ns_name             == ''  or
      ns_name:sub(1, 1)   == '.' or
      ns_name:sub(-1, -1) == '.' or
      ns_name:find("..", 2, true)
    then
      error(("bad name of namespace '%s', null dir name included.")
        :format(ns_name))
  end

  -- 已经存在同名命名空间
  if namespace[ns_name] then
    error(("redefinition of namespace '%s', already existing.")
      :format(ns_name), 2)
  end

  ns = ns or {} -- 空表作为默认值

  -- 禁止同一个命名空间拥有多个名称
  -- 如果要使用别名, 正确的做法是 local alias = namespace.path.to.YourNamespace
  if spacename[ns] then
    error(("mutiple definition of namespace '%s', already defined as '%s'.")
      :format(ns_name, spacename[ns]), 2)
  end

  -- 处理顶层空间
  if not ns_name:find("%.") then
  -- 使用了非法标识符
    if not check_identifier(ns_name) then
      error(("bad name of namespace '%s', identifier excepetd.")
        :format(ns_name), 2)
    end

    namespace[ns_name] = ns
    spacename[ns] = ns_name
    return ns
  end

  -- 处理嵌套命名空间
  local base_name = ns_name:match("(.+)%.") -- 匹配上级命名空间名称
  if base_name then
    local base_ns = namespace[base_name]
      or ns_new(base_name) -- 自动创建上级命名空间
    local ns_shortname = ns_name:match("[^%.]+$") -- 匹配当前命名空间的简短名称

    -- 每一层都必须是合法标识符
    if not check_identifier(ns_shortname) then
      error(("bad name of namespace '%s', identifier excepetd.")
        :format(ns_shortname), 2)
    end

    rawset(base_ns, ns_shortname, ns) -- 嵌入当前命名空间

    namespace[ns_name] = ns
    spacename[ns] = ns_name
    return ns
  end

  error(("bad name of namespace '%s', unable to parse."):format(ns_name), 2)
end


-- 删除命名空间
local function ns_del(ns)

  -- 同时支持名称和对象作为参数
  local ns_name = spacename[ns] or ns

  -- 禁止删除受保护的的命名空间
  if protected[ns_name] then
    error("attempt to delete a protected namespace.", 2)
  end

  local ns = namespace[ns_name]
  if not ns then return end -- 未找到命名空间

  -- 删除命名空间记录
  namespace[ns_name] = nil
  spacename[ns] = nil

  -- 从上层空间中删除嵌套命名空间
  local base_name = ns_name:match("(.+)%.")
  if base_name then
    local base_ns = namespace[base_name]
    local ns_shortname = ns_name:match("[^%.]+$")
    rawset(base_ns, ns_shortname, nil)
  end

  return ns -- 弹出命名空间对象
end


-- 根命名空间迭代器
local function ns_next(_, ns_name)
  if ns_name and not namespace[ns_name] then
    return nil, "not a namespace"
  end
  return next(namespace, ns_name)
end



-- 导出接口
return setmetatable({
  use  = ns_use,
  new  = ns_new,
  del  = ns_del,
  iter = ns_next,
  get  = function(ns_name)
    local ns = namespace[ns_name]
    if ns then return ns end
    return nil, "not a namespace"
  end,
  which = function(ns)
    local path = spacename[ns]
    if path then return path end
    return nil, "not a namespace"
  end
}, {
  __call = function (_, ns_name)
    return function (ns)
      return ns_new(ns_name, ns)
    end
  end,
  __index = namespace
})