--
-- 模块全局共享的弱表元表, 防止创建多个内容相同的表

local setmt = setmetatable

local weak_k  = {__mode='k'}
local weak_v  = {__mode='v'}
local weak_kv = {__mode='kv'}

local function weaken(tb, mode)
  if mode == 'k' then
    return setmt(tb, weak_k)
  elseif mode == 'v' then
    return setmt(tb, weak_v)
  elseif mode == 'kv' then
    return setmt(tb, weak_kv)
  end
end

return weaken
