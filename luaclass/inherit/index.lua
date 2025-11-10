local rawget = rawget

-- 依照MRO查找超类成员
return function(self, name)
  local mro = self.__mro
  for i = 2, mro.n do
    local item = rawget(mro[i], name)
    if item then return item end
  end
  return nil
end
