-- luaclass 导入助手，已适配 packagex 标准
local _M = require "luaclass.luaclass"
local packagex = package.loaded.packagex

if packagex and packagex.inited then
  __export = _M.__export
  else
    local env = _M.__export[1]
    for k, v in next, _M.__export do
      if k ~= 1 then
        env[k] = env[k] or v
      end
    end
end

return _M