local type = type

-- 判断或获取所属类型
local function isinstance(obj, cls)
  local typ = type(obj)
  local obj_cls = typ == "table" and obj.__class

  if not cls then return obj_cls or typ end -- 单参数时返回类型
  if not obj_cls then return typ == cls or "any" == cls end -- Lua 基本类型兼容

  local mro = obj_cls.__mro -- 认为子类实例也是基类类型

  -- 预先判断是否为当前类或 Object 类
  if cls == mro[1] or cls == mro[mro.n] then
    return true
  end

  -- 遍历 MRO 链上剩下的类
  for i = 2, mro.n - 1 do
    if cls == mro[i] then return true end
  end
  return false
end

return isinstance