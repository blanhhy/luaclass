local index  = require "luaclass.inherit.index"
local weaken = require "luaclass.share.weaktbl"

local type, setmetatable, error
    = type, setmetatable, error

local Super = weaken({
  __index = function(proxy, k)
    local field = index(proxy.self, k, proxy.__class)

    if not field then
      error(("No field '%s' existing in superclass of '%s' (start with '%s')")
      :format(k, proxy.self, proxy.__class), 2)
    end

    -- 如果是一个方法
    if type(field) == "function" then
      local function proxyMethod(self, ...)
        return field(self == proxy and proxy.self or self, ...) -- 对象代理方法
      end
      proxy[field] = proxyMethod -- 缓存代理方法
      return proxyMethod
    end

    return field -- 普通字段直接返回
  end;

  __tostring = function(proxy)
    return ("<super: %s, %s>"):format(proxy.__class, proxy.self)
  end;
}, 'k'); -- 弱键模式，对象销毁时清理代理表

local getlocal = debug and debug.getlocal

-- 以某个对象的身份访问它超类上的成员  
-- debug 库可用时, 可以直接 super():foo(), 会自动获取当前方法的 self
---@param obj? Object
---@param cls? luaclass
---@return Super
local function super(obj, cls)
  if not obj then
    local _, self
    if getlocal then _, self = getlocal(2, 1) end -- 尝试获取函数第一参数, 即 self
    obj = self or error("no object provided.", 2) -- 如果没有，抛出一个错误
  end

  cls = cls or obj.__mro[2]

  Super[obj] = Super[obj] or weaken({}, 'k')
  Super[obj][cls] = Super[obj][cls] or setmetatable({
    self     = obj;
    __class  = cls;
  }, Super)

  return Super[obj][cls]
end

return super