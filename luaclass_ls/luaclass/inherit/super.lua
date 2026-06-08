---@meta

---@class super
---@field self object
---@field __class luaclass
---@field [any] any

-- 以某个对象的身份访问它超类上的成员  
-- debug 库可用时, 可以直接 super():foo(), 会自动获取当前方法的 self
---@param obj? object
---@param cls? luaclass
---@return super
function super(obj, cls) end