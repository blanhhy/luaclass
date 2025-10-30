-- 
-- 命名空间管理器

-- 这个 namespace 原本是为 luaclass 设计的, 但不与之耦合
-- 可以广泛地运用于各种模块或项目中

local _M
local _G = _G -- Lua 的全局命名空间
local type, next, rawset, getmetatable, setmetatable = _G.type, _G.next, _G.rawset, _G.getmetatable, _G.setmetatable

local namespace = {_G = _G}     -- 根命名空间容器
local spacename = {[_G] = "_G"} -- 命名空间名称映射
local protected = {_G = true}   -- 禁止删除的命名空间

local weak_MT = {__mode = 'k'}
setmetatable(spacename, weak_MT)
setmetatable(protected, weak_MT)

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
local keywords = {
  "and", "break", "do", "else", "elseif", "end", "false", "for",
  "function", "goto", "if", "in", "local", "nil", "not", "or",
  "repeat", "return", "then", "true", "until", "while"
} -- Lua 关键字

local function check_identifier(str)
  if str == '' then return false end -- 不能为空
  if str:match(_M.unidode and "[^%w_\128-\244]" or "[^%w_]") then return false end -- 不能包含非法字符
  if str:match("^%d") then return false end -- 首字符不能是数字

  -- 不能是保留词
  for i = 1, #keywords do
    if str == keywords[i] then
      return false
    end
  end

  return true
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
local function ns_use()
  
  local ns_list   = {n=0} -- 要使用的命名空间列表
  local ns_portal = {     -- 命名空间访问入口
	["$list"]  = ns_list;
  }
  local ns_MT     = {     -- 命名空间入口的元表
	__index       = ns_get_val;
	__newindex    = disallow;
  }
  
  -- 定义 using 函数
  function ns_portal.using(ns)
    ns = ns and (namespace[ns]or(spacename[ns]and(ns)or(nil)))
    if not ns then error("using nothing!", 2) end
    
    ns_list.n           = ns_list.n + 1
    ns_list[ns_list.n]  = ns
    ns_MT.__newindex    = ns_list[1]
    
    return portal
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


-- 获取命名空间对象和查找命名空间路径
-- get 识别命名空间的全名或表对象, 返回表对象或nil
-- find 只识别命名空间表对象, 返回全名或nil
local function ns_get(id)return(id)and(namespace[id]or(spacename[id]and(id)or(nil)))or(nil)end
local function ns_find(ns)return(ns)and(spacename[ns])or(nil)end


-- 根命名空间迭代器
local function ns_next(_, ns_name)
  if ns_name and not namespace[ns_name] then
    return nil, "not a namespace"
  end
  return next(namespace, ns_name)
end



-- 导出接口
_M = setmetatable({
  use  = ns_use;
  new  = ns_new;
  del  = ns_del;
  get  = ns_get;
  find = ns_find;
  iter = ns_next;
  unicode = not not (load or loadstring) -- 是否允许 unicode 字符
    ("local 〇=0"); -- 默认取决于解释器的实际实现, 可以修改
}, {
  __index = namespace;
  __call = function (_, ns_name)
    local ns_name, var_name = ns_name:match("^([^:]+):*([^:]*)$")
    if var_name and #var_name>0 then return namespace[ns_name][var_name] end
    return function (ns)
      return ns_new(ns_name, ns)
    end
  end;
})

return _M