-- luaclass/inherit/mro.lua
-- This file is a part of luaclass library.

local tostring, concat, error = tostring, table.concat, error

---辅助函数, 寻找好表头
---@param mros {[integer]:luaclass, tail:table<luaclass, boolean>}[]
local function select_head(mros)
  local count = #mros -- 要合并的条数

  for i = 1, count do
    if #mros[i] <= 0 then
      return nil
    end

    local head = mros[i][#mros[i]]
    local is_good = true

    for j = 1, count do
      if j ~= i and mros[j].tail[head] then
        is_good = false
        break
      end
    end

    if is_good then
      for j = 1, count do
        if mros[j][#mros[j]] == head then
          mros[j][#mros[j]] = nil -- 弹出表头
          mros[i].tail[mros[i][#mros[i]] or 0] = nil -- 新表头不再是尾部
        end
      end
      return head
    end
  end

  -- 构造错误信息
  local errMsg = "Cannot create class '%%s' due to MRO conflict. (in bases: %s)\n"
              .. "Current merged MRO: [%%s]"
  
  local bad_heads = {}

  for i = 1, count do
    local head = mros[i][#mros[i]]
    if head then bad_heads[#bad_heads+1] = tostring(head) end
  end

  return nil, errMsg:format(concat(bad_heads, ", "))
end


---@alias MRO luaclass[]

---合并基类的 MRO (C3线性化算法)
---@param cls   luaclass
---@param bases luaclass[]
---@return MRO?, string? errMsg
return function (cls, bases)
  local mro = {cls} -- 先加入自身

  -- 空基类 (不应发生)
  if not bases or not bases[1] then
    return mro
  end

  -- 没有多继承, 无需线性化
  if #bases == 1  then
    local base_mro = bases[1].__mro
    for i = 1, #base_mro do
      mro[i + 1] = base_mro[i]
    end
    return mro
  end

  local mros = {}

  for i = 1, #bases do
    local base = bases[i]
    local base_mro = base.__mro
    local mro_len = #base_mro

    mros[i] = {tail = {}}

    for j = 1, mro_len do
      mros[i][j] = base_mro[mro_len-j+1] -- 逆序记录方便弹出 (不用移动元素)
      mros[i].tail[base_mro[j]] = j ~= 1 -- 方便查询表头是否在其他地方出现
    end
  end

  while true do
    local head, err = select_head(mros) -- 反复选择好表头, 直到没有为止
    
    if err then
      local clsname = cls.__classname or "unknown"
      local mro_strs = {clsname}
      for i = 2, #mro do
        mro_strs[i] = tostring(mro[i])
      end
      return nil, err:format(clsname, concat(mro_strs, ", "))
    end

    if not head then break end
    mro[#mro + 1] = head
  end

  return mro
end