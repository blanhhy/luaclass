local G = _G ---@class _G
local M = require "luaclass.main"

G.class = M.class
G.super = M.super
G.decl  = M.decl
G.namespace  = M.namespace
G.isinstance = M.isinstance
G.luaclass   = M.luaclass
G.Object     = M.Object

return M