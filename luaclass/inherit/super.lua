local _G, type, rawget, setmetatable
    = _G, type, rawget, setmetatable

local index = _G.require "luaclass.inherit.index"

-- 拦截并重定向成员访问
local interceptor = {
  __index = function(cache, k)
    local cls = cache[2] -- 访问者代表的子类
    local spueritem = index(cls, k) -- 寻找超类成员

    -- 如果查找不到，抛出一个错误
    if not spueritem then
      _G.error(("No field or method '%s' existing in superclass of '%s'"):format(k, cls), 2)
    end

    -- 如果找到一个方法，构造闭包
    if type(spueritem) == "function" then
      local function closure(obj, ...)
        return spueritem(obj == cache and cache[1] or obj, ...)
      end
      cache[k] = closure -- 缓存这个闭包
      return closure
    end

    return superitem -- 如果找到一个属性，直接返回
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

-- 以当前身份访问超类的属性或方法
local function super(obj)
  if not obj then
    local _, self
    if debug then _, self = _G.debug.getlocal(2, 1) end -- 如果没有传入类或者对象，尝试获取函数第一参数
    obj = self or _G.error("Failed to find any class.", 2) -- 如果没有，抛出一个错误
  end
  return supercache[obj]
end


return super