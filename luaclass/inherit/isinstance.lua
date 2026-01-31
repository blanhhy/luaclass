-- luaclass/inherit/isinstance.lua
-- This file is a part of luaclass.

local type = type

---判断或获取所属类型
---@param obj any
---@param cls type_check
---@return boolean
---@overload fun(obj:any):type_class
local function isinstance(obj, cls)
  if cls == "any" then return true end

  local typ = type(obj)
  if cls == typ then return true end

  -- 对于可以 index 的类型尝试获取一下 class
  local obj_cls = (typ == "table" or typ == "string") and obj.__class

  if not cls then return obj_cls or typ end -- 单参数时返回类型
  if not obj_cls then return false end

  local mro = obj_cls.__mro -- 认为子类实例也是基类类型

  -- 预先判断是否为当前类或 Object 类
  if cls == mro[1] or cls == mro[mro.n] then
    return true
  end

  -- 遍历 MRO 链上剩下的类
  for i = 2, #mro - 1 do
    if cls == mro[i] then return true end
  end

  return false
end

return isinstance