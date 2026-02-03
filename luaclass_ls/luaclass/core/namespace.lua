---@meta
---@diagnostic disable: undefined-global

---@module "luaclass.core.namespace"
namespace = {}

---@class lua
namespace.lua           = {}

namespace.lua._G        = _G ---@class lua._G : _G
namespace.lua.string    = string or require "string" or nil
namespace.lua.table     = table  or require "table"  or nil
namespace.lua.math      = math   or require "math"   or nil
namespace.lua.io        = io     or require "io"     or nil
namespace.lua.os        = os     or require "os"     or nil
namespace.lua.debug     = debug  or require "debug"  or nil
namespace.lua.bit32     = bit32  or require "bit32"  or nil
namespace.lua.utf8      = utf8   or require "utf8"   or nil
namespace.lua.ffi       = ffi    or require "ffi"    or nil
namespace.lua.jit       = jit    or require "jit"    or nil
namespace.lua.coroutine = coroutine or require "coroutine" or nil
namespace.lua.package   = package   or require "package"   or nil

namespace.lua.class     = require "luaclass.main" ---@class lua.class

---@param name string
---@param ns?  namespace
function namespace.new(name, ns)
    namespace[name] = ns or {}
end