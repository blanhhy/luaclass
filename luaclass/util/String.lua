--
-- 这个类需要单独导入, require "luaclass" 的时候并不会包含luaclass.util.*

local _G = _G
local String = getmetatable('')

if not String then return nil end

local _M = require("luaclass.main")

local luaclass = _M.luaclass
local Object   = _M.Object
local tostring = _G.tostring

---@class stringlib
local stringlib = _G.string or require("string")
String.__index  = stringlib

local string_sub = stringlib.sub
local array_cat  = _G.table.concat

function stringlib.at(str, idx) return string_sub(str, idx, idx) end
function stringlib.join(str, array) return array_cat(array, str) end

String.__classname = "String"
String.__ns_name   = "lua._G"
String.typedef     = "string"
String.__class     = luaclass
String.__mro       = {String, Object, n=2, lv={1, 1, n=2}}
String.valueOf     = tostring

---@Override
function String.__new(_, val)
	if nil == val then return '' end
	local cls = luaclass(val)
	if cls == String or cls == "string" then return val end
	if cls == "table" and val[1] then
		return '{'..array_cat(val, ', ')..'}'
	end
	return tostring(val)
end

for k, v in next, stringlib do String[k] = v end

-- 必要的实例字段和方法
stringlib.__class      = String
stringlib.isInstanceOf = _M.isinstance
stringlib.getClass     = Object.getClass

setmetatable(String, luaclass)
rawset(_G, "String", String)
_M.decl.typedef(String, "string") -- 取代原来的string

return String