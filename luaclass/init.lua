-- luaclass 导入助手，已适配 packagex 标准
local _M = require "luaclass.main"
local ep = _M.__export

local packagex = package.loaded.packagex

if packagex and packagex.inited then
  __export = ep
  else
    local env = ep[1]
    for k, v in next, ep do
      if k ~= 1 then
        env[k] = env[k] or v
      end
    end
end

return _M