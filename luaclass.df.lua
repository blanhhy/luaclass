---@meta
-- luaclass的符号文件 (不要导入)

namespace = require "luaclass.core.namespace"
decl      = require "luaclass.share.declare"

---@param name? string 类名 (传入空串或缺省则为匿名, 实际类名随机)
---@return table
function class(name) end

---@param cls table
---@return table
function super(cls) end

---@param obj any
---@param cls? table|type 类或基本类型
function isinstance(obj, cls) end

luaclass = {}