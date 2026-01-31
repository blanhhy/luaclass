---@meta

---@class Super
---@field self Object
---@field __class luaclass
---@field [any] any

-- 以某个对象的身份访问它超类上的成员  
-- debug 库可用时, 可以直接 super():foo(), 会自动获取当前方法的 self
---@param obj? Object
---@param cls? luaclass
---@return Super
function super(obj, cls) end