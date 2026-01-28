require "luaclass"
require "luaclass.util.String"
-- 字符串适配类, 附加包, 需要单独导入
-- 导入String后lua内置的字符串类型会原地变成String类
-- 完全融入luaclass体系的同时保持了原生特性
-- String类的签名是lua._G::String(lua.class::Object)
-- String类这个对象是字符串原本的元表, 它在原版lua就存在

local str = "hello" ---@cast str String
print(str:getClass()) -- String
print(luaclass(str))  -- String
print(type(str))      -- string

print(str:isInstanceOf(String))  -- true
print(str:isInstanceOf(Object))  -- true
print(isinstance(str, "string")) -- false
-- 唯一的遗憾是isinstance不会把字符串当作原生类型了

print(String{1, 2, 3}) -- {1, 2, 3}
print(String.valueOf(123)) -- 123
-- valueOf方法实际就是_G.tostring函数

-- 加了几个方法, 原版的方法就不说了
-- 用索引取字符
print(("hello"):at(2)) -- e

-- 同 python 的 join 方法
print(('|'):join{"图书", "介绍", "出版社", "价格"}) -- 图书|介绍|出版社|价格
-- 这个方法是对table.concat的包装, 所以如果列表里有不能隐式转换字符串的值会报错
-- 还有一个要注意的是lua不允许index一个字面量, 必需要加括号
