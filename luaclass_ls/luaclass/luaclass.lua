---@meta
-- luaclass的符号文件 (不要导入)

---@class _G
local _G = _G

namespace = require "luaclass.core.namespace"
decl      = require "luaclass.share.declare"

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

---@param name? string 类名 (传入空串或缺省则为匿名, 实际类名随机)
---@return table
function class(name) end

isinstance = require "luaclass.inherit.isinstance"
super      = require "luaclass.inherit.super"

-- 基本元类
luaclass = {}
luaclass.__classname = "luaclass"
luaclass.__ns_name = "lua.class"
luaclass.__class = luaclass
luaclass.defaultns = "lua.class"
luaclass.typedef = "luaclass"

-- 根类, 所有类都是Object的子类
Object = {}
Object.__classname = "Object"
Object.__ns_name = "lua.class"
Object.__class = luaclass
Object.typedef = "Object"
Object.toString = tostring
Object.isInstanceOf = isinstance
