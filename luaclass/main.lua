local _G = _G

local class = _G.require "luaclass.core.class"
local super = _G.require "luaclass.inherit.super"
local nsman = _G.require "luaclass.core.namespace"

local class_NS = nsman.lua.class

local declare    = class_NS.decl
local isinstance = class_NS.isinstance
local luaclass   = class_NS.luaclass
local Object     = class_NS.Object

class_NS.class = class
class_NS.super = super

class_NS.__export = {
  _G;
  luaclass   = luaclass;
  Object     = Object;
  namespace  = nsman;
  decl       = declare;
  isinstance = isinstance;
  class      = class;
  super      = super;
}

return class_NS;