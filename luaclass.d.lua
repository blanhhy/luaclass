---@meta
---@diagnostic disable: undefined-global

---@class object Luaclass中所有对象都是object类型
---@field __class class 该对象所属的类

---@alias MRO class[] 方法解析顺序

---@class class: object, metatable
---@field __classname string 类名
---@field __ns_name   string 命名空间名
---@field __mro       MRO 方法解析顺序
---@field __tostring  fun(self:class):string 类名字符串化
---@field __index     fun(self:class, name:string):any 超类成员查找
---@field __init      fun(self:object, ...:any)? 对象构造函数
---@field __new       fun(self:class, ...:any):object 类实例化方法
---@field new         fun(self:class, ...:any):object 类实例化方法
---@field abstract    boolean? 是否为抽象类
---@field typedef     string?  可声明的类型名
---@field getClass    fun(self:object):class 获取对象的类
---@field isInstance  fun(self:object, class:class):boolean 判断对象是否为指定类的实例
---@field toString    fun(self:object):string 对象字符串化
---@field is          fun(self:object, other:object):boolean 对象比较

---@class metaclass : class
---@field __new fun(mcls:metaclass, name:string, bases?:class[], body?:table):class 类创建方法
---@field defaultns string? 新类的默认命名空间

luaclass = {} ---@class lua._G.luaclass : metaclass
object = {}   ---@class lua._G.object : class

luaclass.__class = luaclass
luaclass.__classname = "luaclass"
luaclass.__ns_name = "lua._G"
luaclass.defaultns = "lua._G"
luaclass.abstract = false
luaclass.typedef = "luaclass"

object.__class = luaclass
object.__classname = "object"
object.__ns_name = "lua._G"
object.abstract = false
object.typedef = "object"

---@alias type_class class|type       包含类的类型
---@alias type_check class|type|"any" 可检查的类型

---luaclass.match方法的返回值类型
---@class type_mismatch
---@field [1]      integer
---@field [2]      type_class
---@field [3]      type_class
---@field pos      integer
---@field expected type_class
---@field actual   type_class
---@field unpack fun(t: type_mismatch): (integer, type_class, type_class)

---检查多个值的类型是否匹配, 返回第一个不匹配的值的信息
---@param v1? any
---@param t1? type_check
---@param v2? any
---@param t2? type_check
---@param v3? any
---@param t3? type_check
---@param ... any
---@return type_mismatch?
function luaclass.match(v1, t1, v2, t2, v3, t3, ...) end

---@alias MenberReceiver fun(tbl:table):class

---类创建器, 用于处理语法  
---```lua
---class "Myclass" (base1, base2, ...) {
---    method = function(self, arg1, arg2)
---        -- do something
---    end;
---}
---```
---其中 ```(base1, base2, ...)``` 这个括号是可选的结构
---
---@param name? string
function class(name)
    ---@overload fun(tbl:table):class 直接接受成员表
    ---@overload fun(...):MenberReceiver 接受基类列表, 返回一个函数, 该函数接受成员表
    return function() end
end

---@class super
---@field self object
---@field __class class
---@field [any] any 超类成员

-- 以某个对象的身份访问它超类上的成员  
-- debug 库可用时, 可以直接 super():foo(), 会自动获取当前方法的 self
---@param obj? object
---@param cls? class
---@return super
function super(obj, cls) end

---@param obj any
---@param cls type_check
---@return boolean
---@overload fun(obj:any):type_class
function isinstance(obj, cls) end

---@module "luaclass.share.declare"
decl = {}

---@module "luaclass.core.namespace"
namespace = {}

---@class lua
namespace.lua           = {}

namespace.lua._G        = _G ---@class _G
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