local rawget = rawget

---依照MRO查找超类成员
---@param self luaclass 类对象
---@param name string   成员名
---@param include_curr? boolean 是否包含当前类
---@param wait_target? luaclass 是否等待目标类
---@return any
return function(self, name, include_curr, wait_target)
  local mro = self.__mro
  local start = include_curr and 1 or 2

  wait_target = wait_target or mro[start]
  local item, occurred = nil, false

  for i = start, mro.n do
    occurred = occurred or mro[i] == wait_target
    if occurred then
      item = rawget(mro[i], name)
      if item ~= nil then break end
    end
  end

  return item
end
