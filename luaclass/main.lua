local isinstance = require "luaclass.inherit.isinstance"
local namespace  = require "luaclass.core.namespace"
local luaclass   = require "luaclass.core.luaclass"
local Object     = require "luaclass.core.Object"
local class      = require "luaclass.core.creator"
local super      = require "luaclass.inherit.super"
local decl       = require "luaclass.share.declare"
local weak       = require "luaclass.share.weaktbl"

-- luaclass 和 Object 的一部分是交叉依赖的
-- 所以在这个文件里面手动设置了依赖关系

Object.__class   = luaclass

setmetatable(luaclass, luaclass)
setmetatable(Object, luaclass)

decl.typedef(luaclass, "luaclass")
decl.typedef(Object, "Object")

-- 创建 class 命名空间  
-- 这将作为 Luaclass 模块的 “干净” 接口
local class_NS = namespace.new("lua.class")

class_NS.class = class
class_NS.super = super
class_NS.decl  = decl
class_NS.namespace  = namespace
class_NS.isinstance = isinstance
class_NS.luaclass   = luaclass
class_NS.Object     = Object

-- 匿名类命名空间
-- kv 弱表, 避免影响垃圾回收
namespace.new("lua.class.anonymous", weak({}, 'kv'))

-- 这是一个兼容的实例化风格
-- 可以用 Clazz:new(...), 相当于 Clazz(...)
Object.new = luaclass.__call

return class_NS