local type = type

-- 判断或获取所属类型
local function isinstance(obj, cls)
  local typ = type(obj)
  local obj_cls = typ == "table" and obj.__class

  if not cls then return obj_cls or typ end -- 单参数时返回类型
  if not obj_cls then return typ == cls or "any" == cls end -- Lua 基本类型兼容

  local mro = obj_cls.__mro

  for i = 1, mro.n do
    if cls == mro[i] then return true end -- 认为子类实例也是基类类型
  end
  return false
end

return isinstance