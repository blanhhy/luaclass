---@meta

---@alias type_class luaclass|type       包含类的类型
---@alias type_check luaclass|type|"any" 可检查的类型

---luaclass.match方法的返回值类型
---@class type_mismatch
---@field [1]      integer
---@field [2]      type_class
---@field [3]      type_class
---@field pos      integer
---@field expected type_class
---@field actual   type_class
---@field unpack fun(t: type_mismatch): (integer, type_class, type_class)

---@module "luaclass.core.luaclass"
luaclass = luaclass