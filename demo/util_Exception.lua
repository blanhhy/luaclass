require "luaclass"
require "luaclass.util.Exception"

-- 本文件介绍 luaclass.util 里的异常类
-- 目前就只有 Exception 和它的子类 TypeError

-- 有了 Exception 类，我们就可以方便地抛出和捕获异常了。
-- 一个完整的异常构造流程是这样的：
-- 
-- Exception(message)
-- :format(args) -- 可选, 格式化 message
-- :attach(info) -- 可选, 附加额外信息供错误处理函数使用
-- :throw([level]) -- 抛出异常 (throw = error 函数)
-- 
-- 根据实际情况, 可以简化可选步骤。
-- Exception 打印出的信息格式是: Exception: message


-- 下面来看看 TypeError 的用法：

-- TypeError 有好几种构造方式:
-- 你可以直接传入一个字符串作为 message:
-- TypeError("bad value type")
-- 还可以 TypeError{msg=message}
-- 还可以 TypeError{expected=xxx, actual=xxx}
-- 还可以 TypeError{expected=xxx, got=xxx} 其中 got 是类型错误的值
-- 对于函数参数错误, 还有专门的构造方式:
-- TypeError(pos, expected, actual)
-- 其中 pos 是参数位置 (从 1 开始), expected 是期望的类型, actual 是实际的类型
-- 或者 TypeError{pos=pos, expected=expected, actual=actual}
-- 或者 TypeError{pos=pos, expected=expected, got=got} 都是 ok 的

-- luaclass.match 是一个静态方法, 用于检查值是否匹配类型
-- 如果有一对不匹配, 它保证返回一个能直接用于构造 TypeError 的对象

-- 下面是一个例子:

function add_numbers(a, b)
    local mismatch = luaclass.match(
        a, "number",
        b, "number"
    )

    if mismatch then
        TypeError(mismatch:unpack())
        :throw()
    end

    return a + b
end

print(add_numbers(1, 2)) -- 3

xpcall(function ()
    add_numbers("1", 2)
end, print)
-- TypeError: bad argument #1, number expected, got string.

-- 可以看到错误检查的过程变得非常简单直观, 而且能自动生成错误信息。
