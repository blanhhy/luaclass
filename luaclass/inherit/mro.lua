-- luaclass/inherit/mro.lua
-- This file is a part of luaclass library.

local tostring, concat = tostring, table.concat

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
  local count = #bases
  local err = false

  for i = 1, count do
    local base = bases[i]
    local base_mro = base.__mro
    local mro_len = #base_mro

    mros[i] = {tail = {}}

    for j = 1, mro_len do
      mros[i][j] = base_mro[mro_len-j+1] -- 逆序记录方便弹出 (不用移动元素)
      mros[i].tail[base_mro[j]] = j ~= 1 -- 方便查询表头是否在其他表尾出现
    end
  end

  while true do -- 反复选择好表头加入 MRO
    local good_head = nil
    local unfinished = false

    for i = 1, count do
      if #mros[i] > 0 then
        unfinished = true
        good_head = mros[i][#mros[i]] -- 选一个表头
        
        for j = 1, count do -- 验证好表头
          if j ~= i and mros[j].tail[good_head] then
            good_head = nil break
          end
        end

        if good_head then break end
      end
    end

    if not good_head then
      err = unfinished -- 合并未结束却没有找到好表头, 说明有循环依赖
      break
    end

    for i = 1, count do
      local mro = mros[i]
      if mro[#mro] == good_head then
        mro[#mro] = nil -- 弹出表头
        mro.tail[mro[#mro] or 0] = nil -- 新表头不再是尾部
      end
    end
    
    mro[#mro + 1] = good_head
  end

  if err then -- 构造错误信息
    local errMsg = "Cannot create class '%s' due to MRO conflict. (in bases: %s)\n"
                .. "Current merged MRO: [%s]"
    local bad_heads = {}
    for i = 1, count do
      local head = mros[i][#mros[i]]
      if head then bad_heads[#bad_heads+1] = tostring(head) end
    end
    local clsname = cls.__classname or "unknown"
    local mro_str = {clsname}
    for i = 2, #mro do mro_str[i] = tostring(mro[i]) end
    return nil, errMsg:format(clsname, concat(bad_heads, ", "), concat(mro_str, ", "))
  end

  return mro
end