local rawget = rawget

---依照MRO查找超类成员
---@param self luaclass 类对象
---@param name string   成员名
---@param include_curr? boolean 是否包含当前类
---@return any
return function(self, name, include_curr)
  local mro = self.__mro
  local start = include_curr and 1 or 2
  for i = start, mro.n do
    local item = rawget(mro[i], name)
    if item then return item end
  end
  return nil
end
