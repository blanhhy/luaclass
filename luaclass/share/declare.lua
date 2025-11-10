--
-- This file is a part of luaclass library.

-- 声明占位符
-- 提供统一的, 带类型的空值占位符, 用于模拟声明变量

local _G = _G
local weaken = _G.require "luaclass.share.weaktb"

local str, num, bool, func, tbl, used, co, any;

str  = function()end
num  = function()end
bool = function()end
func = function()end
tbl  = function()end
used = function()end
co   = function()end
any  = function()end

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

return _G.setmetatable({
  type = types;
  T = function(t)return(phs[t])end; -- 方便取用非变量名的key, eg: decl.T'Math::Vector3'
  typedef = function(typ, name)
    local ph = function()end
    phs[name] = ph
    types[ph] = typ
  end;
}, {__index=phs})