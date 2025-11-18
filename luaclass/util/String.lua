--
-- 这个类需要单独导入, require "luaclass" 的时候并不会包含luaclass.util.*

local _G = _G
local String = _G.getmetatable('')

if not String then return nil end

local _M = _G.require("luaclass.main")

local luaclass = _M.luaclass
local Object   = _M.Object
local tostring = _G.tostring
-- local type     = _G.type

local stringlib = _G.string or _G.require("string")
String.__index  = stringlib

String.__classname = "String"
String.__ns_name   = "_G"
String.__class     = luaclass
String.__mro       = {String, "string", n=2, lv={1, 1, n=2}}

function String:__new(val)
	if nil == val then
		_G.error("Initializing a String value with a nil value.", 3)
	end
	return tostring(val)
end

local next = _G.next
for k, v in next, stringlib do
	String[k] = v
end


stringlib.__class      = String
stringlib.isInstanceOf = _M.isinstance
stringlib.getClass     = Object.getClass
stringlib.toString     = _G.tostring

local string_sub = stringlib.sub

function stringlib:at(idx)
	return string_sub(self, idx, idx)
end


_G.setmetatable(String, luaclass)
_G.rawset(_G, "String", String)

return String