local index  = require "luaclass.inherit.index"
local weaken = require "luaclass.share.weaktb"

local _G, type, setmetatable
    = _G, type, setmetatable

local Super = weaken({
  __index = function(proxy, k)
    local cls   = proxy.__class -- 子类
    local field = index(cls, k) -- 从 mro 中找到这个字段

    -- 超类中没有这个字段
    if not field then
      _G.error(("No field '%s' existing in superclass of '%s'"):format(k, cls), 2)
    end

    -- 是一个方法
    if type(field) == "function" then
      local function proxyMethod(self, ...)
        return field(self == proxy and proxy.self or self, ...) -- 对象代理方法
      end
      proxy[k] = proxyMethod -- 缓存这个闭包到代理表中
      return proxyMethod
    end

    return field -- 普通字段直接返回
  end;

  __tostring = function(proxy)
    return ("<super: %s, %s>"):format(proxy.__class, proxy.self)
  end;
}, 'k'); -- 弱键模式，对象销毁时清理代理表


-- 以某个对象的身份访问它超类上的成员
-- debug 库可用时, 可以直接 super():foo(), 会自动获取当前方法的 self
local function super(obj)
  if not obj then
    local _, self
    if _G.debug then _, self = _G.debug.getlocal(2, 1) end -- 尝试获取函数第一参数, 即 self
    obj = self or _G.error("no object provided.", 2) -- 如果没有，抛出一个错误
  end

  Super[obj] = Super[obj] or setmetatable({
    self       = obj;
    __class    = obj.__class;
  }, Super)

  return Super[obj]
end

return super