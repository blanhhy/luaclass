---@meta

---Luaclass中, 所有对象都是Object类型
---@class Object
---@field __class luaclass
---@field [any] any 成员

---Luaclass中, 所有类都是luaclass类型
---@class luaclass: Object, metatable
---@field __classname string 类名
---@field __ns_name   string 命名空间名
---@field __mro       MRO    方法解析顺序
---@field __tostring  fun(self:luaclass):string 类名字符串化
---@field __index     fun(self:luaclass, name:string):any 超类成员查找
---@field __init      fun(self:Object, ...:any)? 对象构造函数
---@field __new       fun(self:luaclass, ...:any):Object 类实例化方法
---@field new         fun(self:luaclass, ...:any):Object 类实例化方法
---@field abstract    boolean? 是否为抽象类
---@field typedef     string?  可声明的类型名
---@field getClass    fun(self:Object):luaclass 获取对象的类
---@field isInstance  fun(self:Object, class:luaclass):boolean 判断对象是否为指定类的实例
---@field toString    fun(self:Object):string 对象字符串化
---@field is          fun(self:Object, other:Object):boolean 对象比较

---Object是一个类, 它是所有类的基类, 因此所有对象都是Object类型
---Object定义了一些通用方法, 如getClass, isInstance, toString, is等
---@module "luaclass.core.Object"
Object = Object