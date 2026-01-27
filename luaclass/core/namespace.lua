--
-- 命名空间管理器

-- 这个 namespace 原本是为 luaclass 设计的, 但不与之耦合
-- 可以广泛地运用于各种模块或项目中

local conf = {} -- 一些模块配置

conf.luaver = tonumber(_VERSION:sub(5)) ---@type number 解释器版本号

-- 变量名是否允许 unicode 字符
-- 默认取决于解释器的实际实现, 可以修改
local load = conf.luaver > 5.1 and load or loadstring
conf.unicode_supported = pcall(load, "local 〇=0")

-- 是否允许任意命名空间环境访问 lua, 如直接 io.open 而不是 lua.io.open
-- 为了贴合 Lua 使用习惯, 默认开启
conf.allow_access_lua = true

-- 是否自动 using "lua._G", 默认关闭
conf.auto_using_G = false


---@alias namespace table 任意表都可以作为命名空间

local _M
local _G = _G ---@type namespace Lua 的全局命名空间
local type, next, rawget, rawset, setmetatable, error
    = type, next, rawget, rawset, setmetatable, error

local setfenv = conf.luaver <= 5.1 and _G.setfenv


local lua = {_G = _G} ---@type namespace Lua 根命名空间

local namespace = {lua = lua, ["lua._G"] = _G}     ---@type table<string, namespace> 根命名空间容器
local spacename = {[lua] = "lua", [_G] = "lua._G"} ---@type table<namespace, string> 命名空间名称映射
local protected = {lua = true, ["lua._G"] = true}  ---@type table<string, boolean> 禁止删除的命名空间

local weaken = _G.require "luaclass.share.weaktbl"
weaken(spacename, 'k')
weaken(protected, 'k')

-- 如果有人需要在别处使用这个库的话,
-- 可以删除上面的 weaken, 然后取消下面的注释 (文件中不止这一处)

--[[ local weak_MT = {__mode = 'k'}
setmetatable(spacename, weak_MT)
setmetatable(protected, weak_MT) ]]


-- 尝试注册一些 Lua 标准库
local function prequire(name)
  local ok, lib = pcall(require, name)
  if ok then
    lua[name] = lib
    name = "lua."..name
    namespace[name] = lib
    protected[name] = true
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

-- 命名空间视作已导入的模块, 注册到 package.loaded 中
setmetatable(package.loaded, {__index = namespace})




-- 辅助函数：检查合法标识符
conf.keywords = {
  "and", "break", "do", "else", "elseif", "end", "false", "for",
  "function", "if", "in", "local", "nil", "not", "or", "repeat",
  "return", "then", "true", "until", "while", conf.luaver > 5.1 and "goto" or nil
} -- Lua 关键字 (如果解释器支持更多关键字, 可以自行添加)

local function check_identifier(str)
  if str == '' then return false end -- 不能为空
  if str:match(conf.unicode_supported and "[^%w_\128-\244]" or "[^%w_]") then return false end -- 不能包含非法字符
  if str:match("^%d") then return false end -- 首字符不能是数字

  -- 不能是保留词
  for i = 1, #conf.keywords do
    if str == conf.keywords[i] then
      return false
    end
  end

  return true
end


-- 命名空间环境的元表
local ns_env_MT = {}

function ns_env_MT:__index(name)
  local value
  local ns_list = self["$list"]
  for i = 1, ns_list.n do
    value = ns_list[i][name]
    if nil ~= value then
      return value
    end
  end
  if conf.allow_access_lua then
    return lua[name] or namespace[name] -- 允许访问 lua
  end
  return namespace[name] -- 允许全名访问其他命名空间
end

---从命名空间中导入对象
---@param name     string 要导入的对象名称
---@param ns_name? string 要导入的命名空间名称
local function import_from_ns(name, ns_name)
  if not name then return nil end
  ns_name = ns_name or "lua"

  local ns = namespace[ns_name]
  local obj = ns and ns[name]
  if not ns then return nil, ("no namespace '%s'"):format(ns_name) end
  if nil == obj then return nil, ("no object '%s' in namespace '%s'"):format(name, ns_name) end

  return obj
end

-- 使用命名空间, 返回一个用作 _ENV 的表
local function ns_use()

  local ns_list   = {n=0} -- 要使用的命名空间列表
  local ns_env    = {     -- 命名空间访问入口
    ["$list"]     = ns_list;
    namespace     = _M;   -- 访问本模块
  }

  -- setmetatable(ns_list, {__mode='v'})
  weaken(ns_list, 'v') -- 弱引用命名空间表

  -- 定义 using 函数, 向使用的命名空间列表中添加命名空间
  function ns_env.using(ns)
    ns = ns and (namespace[ns]or(spacename[ns]and(ns)or(nil)))
    if not ns then error("using nothing!", 2) end
    ns_list.n           = ns_list.n + 1
    ns_list[ns_list.n]  = ns
    return ns_env
  end

  -- 从命名空间导入对象到当前环境中, eg: import "lua.math.pi"; import "MyModule.*"
  function ns_env.import(fullname)
    local ns_name, name = fullname:match("^(.+)%.([^%.]+)$")

    if name ~= '*' then
      local obj, err = import_from_ns(name, ns_name)
      if not obj then error(err, 2) end
      ns_env[name] = obj
      return obj
    end

    local ns = namespace[ns_name]
    if not ns then error(("no namespace '%s' found for import."):format(ns_name), 2) end
    for k, v in next, ns do
      if nil == rawget(ns_env, k) and check_identifier(k) then
        ns_env[k] = v
      end
    end
  end

  if conf.auto_using_G then
    ns_env.using(_G)
  end

  -- 适配旧版_ENV机制(常见于luajit)
  if setfenv then
    ns_env._ENV = ns_env
    setfenv(2, ns_env)
  end

  return setmetatable(ns_env, ns_env_MT)
end


---创建命名空间
---@return namespace
local function ns_new(...)
  local ns_name, ns = ...
  local nargs = select('#', ...)

  -- 参数与类型校验
  if nargs == 0 then
    error("bad argument #1 to 'namespace.new' (value expected)", 2)
  end

  if nargs >= 1 and type(ns_name) ~= "string" then
    error(("bad argument #1 to 'namespace.new' (string excepetd, got %s).")
      :format(type(ns_name)), 2)
  end

  if nargs >= 2 and type(ns) ~= "table" then
    error(("bad argument #2 to 'namespace.new' (table excepetd, got %s).")
      :format(type(ns)), 2)
  end

  -- 基础格式校验, 排除各个环节出现的的空字符串
  if  ns_name             == ''  or
      ns_name:sub(1, 1)   == '.' or
      ns_name:sub(-1, -1) == '.' or
      ns_name:find("..", 2, true)
    then
      error(("bad namespace name '%s', null dir name included.")
        :format(ns_name), 2)
  end

  -- 已经存在同名命名空间, 重新打开它
  if namespace[ns_name] then
    local old_ns = namespace[ns_name]
    if protected[ns_name] then
      error(("attempt to re-open a protected namespace '%s'."), 2)
    end
    if not ns or ns == old_ns then return old_ns end -- 完全相同, 无需修改
    for k, v in next, ns do
      if nil ~= old_ns[k] then old_ns[k] = v end
    end
    return old_ns
  end

  -- 禁止同一个命名空间拥有多个名称
  -- 如果要使用别名, 正确的做法是 local alias = namespace.path.to.YourNamespace
  if ns and spacename[ns] then
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

    ns = ns or {} -- 空表作为默认值

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

    -- 已经存在同名变量
    -- 如果是表而且参数没有提供表就直接采用
    -- 如果参数已经提供和已有变量不一样就报错
    local exist_var = rawget(base_ns, ns_shortname)
    if ns and nil ~= exist_var and ns ~= exist_var then
      error(("conflict definition of namespace '%s', already defined as a %s value.")
        :format(ns_shortname, type(exist_var)), 2)
    end

    ns = ns or (type(exist_var) == "table" and exist_var) or {}
    rawset(base_ns, ns_shortname, ns) -- 嵌入当前命名空间

    namespace[ns_name] = ns
    spacename[ns] = ns_name

    return ns
  end

  error(("bad name of namespace '%s', unable to parse."):format(ns_name), 2)
end


---删除命名空间记录
---@param ns namespace|string
---@return namespace? deleted
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

  return ns
end


---获取命名空间对象
---@param id string|namespace
---@return namespace? ns_obj
local function ns_get(id)
  return (id                  -- 没有参数直接返回nil
  and  (namespace[id]         -- 首先假设是名称查找表, 有就返回
    or (spacename[id] and id) -- 否则假设是对象查找表, 有就返回
    or nil)                   -- 都没找到, 返回nil
    or nil)
end

---查找命名空间路径
---@param ns namespace
---@return string? ns_name
local function ns_find(ns)
  if ns then return spacename[ns] end
end

---根命名空间迭代器
---@param ns_name string?
local function ns_next(_, ns_name)
  return next(namespace, ns_name)
end


-- 导出接口
_M = {
  use  = ns_use;
  new  = ns_new;
  del  = ns_del;
  get  = ns_get;
  find = ns_find;
  iter = ns_next;
  load = import_from_ns;
  conf = conf;
}

local _M_mt = {
  __call = function (_, ns_name)
    return function (ns) return ns_new(ns_name, ns) end
  end;
}

setmetatable(_M, _M_mt)

-- 由于lua_ls插件的bug (疑似), use函数会被错误推断为__index表的值类型
-- 目前暂且只能这么写, 为了阻止插件识别到__index, 什么时候解决了再改回来
_M_mt.__index = namespace

return _M