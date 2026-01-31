local rawget = rawget

---依照MRO查找超类成员
---@param self Object 任意对象
---@param name string 成员名
---@param wait_target? luaclass 是否等待目标类
---@return any
return function(self, name, wait_target)
  local mro = self.__mro
  local start = self ~= mro[1] and 1 or 2

  wait_target = wait_target or mro[start]
  local item, occurred = nil, false

  for i = start, #mro do
    occurred = occurred or mro[i] == wait_target
    if occurred then
      item = rawget(mro[i], name)
      if item ~= nil then break end
    end
  end

  return item
end
