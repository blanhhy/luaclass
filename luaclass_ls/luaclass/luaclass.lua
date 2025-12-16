---@meta
-- luaclass的符号文件 (不要导入)

---@class _G
local _G = _G

---@alias Object {__class:luaclass, [any]:any} luaclass 对象
---@alias luaclass {__classname:string, [any]:any} luaclass 类对象
---@alias class luaclass|type 类型, 可能是 luaclass 类对象或 Lua 类型字符串

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
---@return luaclass|fun(...:luaclass):luaclass
function class(name) end

isinstance = require "luaclass.inherit.isinstance"
super      = require "luaclass.inherit.super"

-- 基本元类, 可以创建类实例或获取任意对象的类型, 所有元类应当继承自此类
---@overload fun(obj:any):class
---@overload fun(name?:string, bases:luaclass[], tbl:table):luaclass
luaclass = {}
luaclass.__class = luaclass
luaclass.__classname = "luaclass"
luaclass.__ns_name = "lua.class"
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
