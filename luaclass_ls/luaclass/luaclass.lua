---@meta
-- luaclass的符号文件 (不要导入)

local G = _G ---@class _G
local M = require "luaclass.main"

class = M.class
super = M.super
decl  = M.decl
namespace  = M.namespace
isinstance = M.isinstance
luaclass   = M.luaclass
Object     = M.Object

namespace.string    = require "string"
namespace.table     = require "table"
namespace.math      = require "math"
namespace.io        = require "io"
namespace.os        = require "os"
namespace.debug     = require "debug"
namespace.coroutine = require "coroutine"
namespace.package   = require "package"
namespace.bit32     = require "bit32"
namespace.utf8      = require "utf8"
namespace.ffi       = require "ffi"
namespace.jit       = require "jit"
