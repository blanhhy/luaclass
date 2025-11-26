local index = require "luaclass.inherit.index"

local _G, type, rawget, setmetatable
    = _G, type, rawget, setmetatable


-- 拦截并重定向成员访问
local interceptor = {
  __index = function(cache, k)
    local cls = cache[2] -- 访问者代表的子类
    local field = index(cls, k)

    -- 超类中没有这个字段
    if not field then
      _G.error(("No field or method '%s' existing in superclass of '%s'"):format(k, cls), 2)
    end

    -- 找到一个方法
    if type(field) == "function" then
      local function closure(obj, ...)
        return field(obj == cache and cache[1] or obj, ...)
      end
      cache[k] = closure -- 缓存这个闭包
      return closure
    end

    return field -- 普通字段直接返回
  end
}


-- 缓存 super 调用结果
local supercache = setmetatable({}, {
  __mode = 'k', -- 弱键模式，对象销毁时清理缓存
  __index = function(self, obj)
    local cache = setmetatable({obj,
      rawget(obj, "__classname") and obj or obj.__class
    }, interceptor)
    self[obj] = cache
    return cache
  end
})


local debug = not not _G.debug

-- 以当前身份访问超类字段
local function super(obj)
  if not obj then
    local _, self
    if _G.debug then _, self = _G.debug.getlocal(2, 1) end -- 如果没有传入类或者对象，尝试获取函数第一参数
    obj = self or _G.error("Failed to find any class.", 2) -- 如果没有，抛出一个错误
  end
  return supercache[obj]
end


return super