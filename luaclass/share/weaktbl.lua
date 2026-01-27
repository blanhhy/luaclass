--
-- 模块全局共享的弱表元表, 防止创建多个内容相同的表

local setmetatable = setmetatable
local weak_k, weak_v, weak_kv

---@param tbl table
---@param mode "k"|"v"|"kv"
---@return table
local function weaken(tbl, mode)
  if mode == 'k' then
    weak_k = weak_k or {__mode='k'}
    return setmetatable(tbl, weak_k)
  elseif mode == 'v' then
    weak_v = weak_v or {__mode='v'}
    return setmetatable(tbl, weak_v)
  elseif mode == 'kv' then
    weak_kv = weak_kv or {__mode='kv'}
    return setmetatable(tbl, weak_kv)
  end
  return tbl
end

return weaken
