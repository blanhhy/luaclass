--
-- This file is a part of luaclass library.

-- 声明占位符
-- 提供统一的, 带类型的空值占位符, 用于模拟声明变量

-- local _G = _G
local weaken = require "luaclass.share.weaktbl"

local str, num, bool, func, tbl, used, co, any;

str  = function()end ---@type placeholder
num  = function()end ---@type placeholder
bool = function()end ---@type placeholder
func = function()end ---@type placeholder
tbl  = function()end ---@type placeholder
used = function()end ---@type placeholder
co   = function()end ---@type placeholder
any  = function()end ---@type placeholder


local phs = weaken({
	string   = str;
	number   = num;
	boolean  = bool;
	method   = func;
	table    = tbl;
	userdata = used;
	thread   = co;
	any      = any;
}, 'k')

---@type table<placeholder, type_check>
local types = weaken({
  [str]  = "string";
  [num]  = "number";
  [bool] = "boolean";
  [func] = "function";
  [tbl]  = "table";
  [used] = "userdata";
  [co]   = "thread";
  [any]  = "any";
}, 'kv')

local decl = {
  type = types; -- 通过占位符获取类型标志 (字符串或自定义的对象), eg: decl.type[decl.string] -> "string"
  
  ---方便取用非变量名的key, eg: decl.T'Math::Vector3'
  ---@param t string
  ---@return function
  T = function(t)
    return phs[t]
  end;

  ---声明类型别名, eg: decl.typedef(MyString, 'MyString')
  ---@param cls type_class
  ---@param name string
  typedef = function(cls, name)
    local ph = function()end
    phs[name] = ph
    types[ph] = cls
  end;
}

return setmetatable(decl, {__index=phs})