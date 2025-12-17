require "luaclass"
require "luaclass.util.LuaArray"

-- 本文件演示 LuaArray 类的用法
-- LuaArray 是基于 luaclass 的数组适配类, 为 Lua 的数组添加了许多功能

-- 创建一个LuaArray实例
local originalNumbers = LuaArray(34, 6577, 8, 1, 85, 5635, 3)
print("创建数组: originalNumbers = " .. tostring(originalNumbers))
print()

-- LuaArray 可以从参数列表或已有的数组来创建, 或创建空数组
-- LuaArray(3, 4, 5)
-- LuaArray{1, 2, 3, 4, 5}
-- LuaArray()

-- 排序数组
local sortedNumbers = originalNumbers:copy()
sortedNumbers:sort()
print("排序操作:")
print("   before: " .. tostring(originalNumbers))
print("   after:  " .. tostring(sortedNumbers))
print()

-- 排序方法就是 table.sort 函数

-- 反转数组
local reversedNumbers = sortedNumbers:copy()
reversedNumbers:reverse()
print("反转操作:")
print("   before: " .. tostring(sortedNumbers))
print("   after:  " .. tostring(reversedNumbers))
print()

-- 反转方法是原地操作, 同时会返回 self

-- 截取子数组
local subArray = reversedNumbers:sub(3, 5)
print("截取子数组:")
print("   source:  " .. tostring(reversedNumbers))
print("   slice(3,5): " .. tostring(subArray))
print("   获取了索引3到5的元素：[索引3]" .. reversedNumbers[3] .. ", [索引4]" .. reversedNumbers[4] .. ", [索引5]" .. reversedNumbers[5])
print()

-- sub 的索引规则和 lua 的 string.sub 一致

-- 扩充新元素
local extendedArray = reversedNumbers:copy()
local newElements = {1, 3, 6, 3, 9}
extendedArray:extend(newElements)
print("扩展操作:")
print("   original: " .. tostring(reversedNumbers))
print("   newElements: " .. "{1, 3, 6, 3, 9}")
print("   extended: " .. tostring(extendedArray))
print()

-- extend 可以批量扩充元素, 也可以用来连接数组
-- 是原地操作, 同时会返回 self

-- 查找所有匹配值的索引
local indicesOf3 = extendedArray:indices(3)
print("查找值3的所有索引:")
print("   array: " .. tostring(extendedArray))
print("   indicesOf3: " .. tostring(indicesOf3))
print("   unpack: " .. table.concat({indicesOf3:unpack()}, ", "))
print()

-- 查找索引有 index, lastIndex, indices 三个方法
-- 顾名思义, index 返回第一个匹配的索引, lastIndex 返回最后一个匹配的索引, indices 返回所有匹配的索引
-- indiecs 返回的也是 LuaArray 对象

-- 删除第一个匹配值
local withoutFirst3 = extendedArray:copy()
withoutFirst3:remove(3)
print("删除第一个3:")
print("   before: " .. tostring(extendedArray))
print("   after:  " .. tostring(withoutFirst3))
print()

-- 删除最后一个匹配值
local withoutLast3 = withoutFirst3:copy()
withoutLast3:removeLast(3)
print("删除最后一个3:")
print("   before: " .. tostring(withoutFirst3))
print("   after:  " .. tostring(withoutLast3))
print()

-- 移除值也有 remove, removeLast, removeAll 三个方法
-- 和 index 那三个类似, 分别是移除第一个, 移除最后一个, 和移除所有匹配的元素
-- 其中 remove 和 removeLast 返回原来那个值的索引, 而 removeAll 返回被移除的个数

-- 获取唯一值数组
local uniqueValues = withoutLast3:unique()
print("去重操作:")
print("   before: " .. tostring(withoutLast3))
print("   unique: " .. tostring(uniqueValues))
print()

-- unique 用于去重, 得到一个新的数组, 原数组不变
-- 还有一个去重相关的方法 values, 用于得到值的集合, 自然是不重复的
-- values 方法返回的是键为数组值, 值为它们第一次出现的索引的 table

-- 创建和填充数组
print("创建和操作:")
local defaultArray = LuaArray.create(5)
print("   LuaArray.create(5) = " .. tostring(defaultArray))

-- create 不指定填充值的话, 默认是 0
-- 在 jit 环境下有优化, 会调用 table.new 来预分配空间

defaultArray:fill(7)
print("   fill(7) -> " .. tostring(defaultArray))

-- fill 可以指定填充区间, 默认是整个数组

defaultArray:clear()
print("   clear() -> " .. tostring(defaultArray) .. ", length = " .. defaultArray.length)
print()

-- clear 在 jit 环境下会调用 table.clear

-- 切片操作
print("切片操作:")
print("   source: " .. tostring(uniqueValues))
local sliceStep2 = uniqueValues(2, -2, 2) -- 从第二个到倒数第二个, 间隔为2的切片
print("   slice(2, -2, 2): " .. tostring(sliceStep2))
print()

-- 数组切片用小括号和调用 sub 方法是一样的, 同一个函数
-- 数组切片与 python 类似, 也有切片步长 step 参数
-- 但是要注意索引的原则, 应该参考 string.sub 的规则

-- 重复和连接操作
print("重复和连接操作:")
local smallArray1 = LuaArray(1, 2, 3)
local repeatedArray = smallArray1 * 2
print("   {1,2,3} * 2 = " .. tostring(repeatedArray))

-- 重复可以用 * 符号, 也可以用 rep 方法
-- 是为了模仿 python 风格, * 会调用 rep 方法

local smallArray2 = LuaArray(4, 5, 6)
local concatenatedArray = smallArray1 .. smallArray2
print("   {1,2,3} .. {4,5,6} = " .. tostring(concatenatedArray))
print()

-- 连接符号和 extend 方法不一样, .. 会返回新的数组, 不会修改原数组
-- 和 concat 也不一样, concat 是 table 库的 concat, 是用来拼接字符串的

-- 最大值和最小值
print("统计操作:")
local randomArray = LuaArray()
for i = 1, 20 do
    randomArray:append(math.random(1, 16))
end
print("   randomArray: " .. tostring(randomArray))
print("   max: " .. randomArray:max() .. ", min: " .. randomArray:min())

local targetValue = randomArray[10]
local countResult = randomArray:count(targetValue)
print("   count(" .. targetValue .. "): 出现 " .. countResult .. " 次")
print()

-- 最值方法使用 lua 的大于小于符号, 会受元方法影响
-- 需要保证数组内的元素都互相可比

-- 数组比较
print("数组比较:")
local arrA = LuaArray(1, 2, 3, 4, 5)
local arrB = LuaArray(1, 2, 3, 4, 5)
print("   arrA = " .. tostring(arrA))
print("   arrB = " .. tostring(arrB))
print("   arrA == arrB? " .. tostring(arrA == arrB)) -- 是否相等, 比较的是内容
print("   arrA is arrB? " .. tostring(arrA:is(arrB))) -- 是否为同一个对象, 比较的是地址

-- == 比较的是内容, is 比较的是地址
-- is 方法来自 Object 类, 和 rawequal 是同一个函数

arrA:insert(2, 6)
print("   arrA插入6后: " .. tostring(arrA))
print("   arrA > arrB? " .. tostring(arrA > arrB)) -- 比较的是第一个不等元素
print()

-- 不等号会先比较长度, 长度不同则比较第一个不等元素

-- 可以和普通 table 对象比较
print("和普通 table 对象比较:")
local arrC = {1, 2, 3, 4, 5}
print("   arrC = table: " .. table.concat(arrC, ", "))
print("   arrA > arrC? " .. tostring(arrA > arrC))
print("   arrB == arrC? " .. tostring(arrB == arrC))

-- 比较数组的时候至少有一个是 LuaArray 对象即可, 普通的 table 数组也可以参与
-- 其他的类型不行 (除非它们也有元方法且处于优先地位)

-- 还有其他的方法比如 pop弹出, copy 复制, 等等, 都比较简单
-- 复制数组也可以直接用构造函数实现
-- arr2 = LuaArray(arr1)

-- 以及 ipairs 和 unpack 方法, 就是 lua 原来的 ipairs 和 unpack 函数
-- for i, v in arr:ipairs() do
--     print(i, v)
-- end
-- v1, v2, v3, ... = arr:unpack()
