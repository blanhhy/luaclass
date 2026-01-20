--
-- 模块全局共享的弱表元表, 防止创建多个内容相同的表

local setmetatable = setmetatable
local weak_k, weak_v, weak_kv

local function weaken(tb, mode)
  if mode == 'k' then
    weak_k = weak_k or {__mode='k'}
    return setmetatable(tb, weak_k)
  elseif mode == 'v' then
    weak_v = weak_v or {__mode='v'}
    return setmetatable(tb, weak_v)
  elseif mode == 'kv' then
    weak_kv = weak_kv or {__mode='kv'}
    return setmetatable(tb, weak_kv)
  end
end

return weaken
