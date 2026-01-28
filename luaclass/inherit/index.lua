local rawget = rawget

---依照MRO查找超类成员
---@param self luaclass 类对象
---@param name string   成员名
---@return any
return function(self, name)
  local mro = self.__mro
  local start = self == mro[1] and 2 or 1
  for i = start, mro.n do
    local item = rawget(mro[i], name)
    if item then return item end
  end
  return nil
end
