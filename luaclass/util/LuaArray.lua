-- luaclass/util/LuaArray.lua
-- 这个类需要单独导入, require "luaclass" 的时候并不会包含luaclass.util.*
if not class then
    require "luaclass"
end

local isJIT = namespace.lua.jit and true or false
local table_new, table_clear

if isJIT then
    table_new = require "table.new"
    table_clear = require "table.clear"
end

local type = type
local tostring = tostring
local Int = math.floor
local remove = table.remove

class "LuaArray" {
    ---@static
    chkidxEnabled = true;

    -- 工具函数, 检查索引是否有效
    ---@static
    ---@param lim number
    ---@param length? integer 如果提供了 length, 返回值会被规范为正向索引
    ---@return integer index 索引是一个在 [1, lim] 范围内的整数
    chkidx = function(index, lim, length)
        if not LuaArray.chkidxEnabled then return index end
        local err = (
            (type(index) ~= "number" or Int(index) ~= index) and
            ("<integer> expected, got <%s>."):format(isinstance(index))
        ) or (
            (index == 0 or index > lim or -index > lim) and
            "Array index out of range"
        )
        if err then error(err, 3) end
        if length and index < 0 then return index + 1 + length end
        return index
    end;

    -- 初始化, 填充可能的初始值, 并设置长度
    ---@Constructor
    __init = function(self, array)
        if not array then return end

        if type(array) ~= "table" then
            error(("<table?> expected, got <%s>."):format(isinstance(array)), 2)
        end

        local length = 0
        for i, v in ipairs(array) do
            self[i] = v
            length = i
        end
        self.length = length
    end;

    ---@Override
    __tostring = function(self)
        local strList = {}
        for i = 1, self.length do
            strList[i] = tostring(self[i])
        end
        return '{'..table.concat(strList, ", ")..'}'
    end;

    copy = function(self)
        local copy = LuaArray:__new()
        for i = 1, self.length do
            copy[i] = self[i]
        end
        copy.length = self.length
        return copy
    end;

    append = function(self, value)
        if nil == value then
            error("Cannot add nil into a LuaArray", 2)
        end
        self.length = self.length + 1
        self[self.length] = value
    end;

    ---@param index? integer 默认在数组末尾
    insert = function(self, index, value)
        index = index and LuaArray.chkidx(index, self.length + 1, self.length) or self.length + 1
        if nil == value then
            error("Cannot add nil into a LuaArray", 2)
        end
        self.length = self.length + 1
        return table.insert(self, index, value)
    end;

    ---@param index? integer 默认在数组末尾
    pop = function(self, index)
        index = index and LuaArray.chkidx(index, self.length, self.length) or self.length
        self.length = self.length - 1
        return remove(self, index)
    end;

    index = function(self, value)
        if nil == value then
            error("non-nil value expected.", 2)
        end
        for i = 1, self.length do
            if value == self[i] then return i end
        end
        return nil
    end;

    lastIndex = function(self, value)
        if nil == value then
            error("non-nil value expected.", 2)
        end
        for i = self.length, 1, -1 do
            if value == self[i] then return i end
        end
        return nil
    end;

    indices = function(self, value)
        if nil == value then
            error("non-nil value expected.", 2)
        end
        local indices = LuaArray:__new()
        local count = 0
        for i = 1, self.length do
            if value == self[i] then
                count = count + 1
                indices[count] = i
            end
        end
        indices.length = count
        return indices
    end;

    remove = function(self, value)
        if nil == value then
            error("non-nil value expected.", 2)
        end
        for i = 1, self.length do
            if value == self[i] then
                remove(self, i)
                self.length = self.length - 1
                return i
            end
        end
        return nil
    end;

    removeLast = function(self, value)
        if nil == value then
            error("non-nil value expected.", 2)
        end
        for i = self.length, 1, -1 do
            if value == self[i] then
                remove(self, i)
                self.length = self.length - 1
                return i
            end
        end
        return nil
    end;

    removeAll = function(self, value)
        if nil == value then
            error("non-nil value expected.", 2)
        end
        for i = self.length, 1, -1 do
            if value == self[i] then
                remove(self, i)
                self.length = self.length - 1
            end
        end
    end;

    concat = table.concat;
    unpack = table.unpack or unpack;
    ipairs = ipairs;
    sort   = table.sort;

    -- 用另一个数组扩展当前数组
    ---@param array table
    extend = function(self, array)
        if type(array) ~= "table" then
            error(("<table?> expected, got <%s>."):format(isinstance(array)), 2)
        end
        local length = self.length
        local count = 0
        for i, v in ipairs(array) do
            self[length + i] = v
            count = i
        end
        self.length = length + count
        return self
    end;

    -- 连接两个数组, 得到一个新的数组
    __concat = function(arr1, arr2)
        if not isinstance(arr1, LuaArray) or not isinstance(arr2, LuaArray) then
            error(("attempt to concat LuaArray with a %s value")
                :format(isinstance(arr1, LuaArray) and luaclass(arr2) or luaclass(arr1)), 2)
        end

        local newArr
        local length = arr1.length + arr2.length

        if isJIT then
            newArr = table_new(length, 2)
            newArr.__class = LuaArray
            setmetatable(newArr, LuaArray)
        else
            newArr = LuaArray:__new()
        end

        newArr.length = length

        for i = 1, arr1.length do
            newArr[i] = arr1[i]
        end

        for i = 1, arr2.length do
            newArr[arr1.length + i] = arr2[i]
        end

        return newArr
    end;

    ---@param i? integer
    ---@param j? integer
    reverse = function(self, i, j)
        i = i and LuaArray.chkidx(i, self.length, self.length) or 1
        j = j and LuaArray.chkidx(j, self.length, self.length) or self.length
        while i < j do
            self[i], self[j] = self[j], self[i]
            i = i + 1
            j = j - 1
        end
        return self
    end;

    ---@param i? integer
    ---@param j? integer
    ---@param step? integer
    sub = function(self, i, j, step)
        i = i and LuaArray.chkidx(i, self.length, self.length) or 1
        j = j and LuaArray.chkidx(j, self.length, self.length) or self.length
        step = step and LuaArray.chkidx(step, math.huge) or 1

        local slice = LuaArray:__new() -- 内部构造函数, 为了下面手动初始化
        local count = 0

        for o = i, j, step do
            count = count + 1
            slice[count] = self[o]
        end

        slice.length = count

        return slice
    end;

    -- 复制数组 n 次, 得到一个新的数组
    ---@param n integer
    rep = function(self, n)
        if type(n) ~= "number" or Int(n) ~= n then
            error(("<integer> expected, got <%s>."):format(n))
        end

        if n <= 0 then return LuaArray() end

        local newArr
        local length = self.length * n

        if isJIT then
            newArr = table_new(length, 2)
            newArr.__class = LuaArray
            setmetatable(newArr, LuaArray)
        else
            newArr = LuaArray:__new()
        end

        newArr.length = length

        for i = 1, self.length do
            for j = 0, n - 1 do
                newArr[i + j * self.length] = self[i]
            end
        end

        return newArr
    end;

    -- 类 Python 的数组重复操作
    -- eg: arr = LuaArray{1, 2, 3} * 2
    __mul = function(left, right)
        if not isinstance(left, LuaArray) then
            return right:rep(left)
        end
        return left:rep(right)
    end;

    -- 获取值的集合, 顺便包含第一次出现的索引
    values = function(self)
        local values = {}
        for i = self.length, 1, -1 do
            values[self[i]] = i
        end
        return values
    end;

    -- 获取去重数组
    unique = function(self)
        local unique = LuaArray:__new()
        local seen = {}
        local count = 0
        for i = 1, self.length do
            local value = self[i]
            if not seen[value] then
                seen[value] = true
                count = count + 1
                unique[count] = value
            end
        end
        unique.length = count
        return unique
    end;

    clear = function(self)
        if isJIT then
            table_clear(self, self.length) -- 保留元表
            self.__class = LuaArray -- 重绑class
            self.length = 0 -- 重置length
            return self
        end
        for i = 1, self.length do
            self[i] = nil
        end
        self.length = 0
        return self
    end;

    ---@static
    ---@param length integer
    ---@param value? any
    -- 创建一个指定长度的数组, 并填充默认值
    create = function(length, value)
        if nil == value then value = 0 end
        length = LuaArray.chkidx(length, math.huge)

        local arr

        if isJIT then
            arr = table_new(length, 2)
            arr.__class = LuaArray
            setmetatable(arr, LuaArray)
        else
            arr = LuaArray:__new()
        end

        arr.length = length

        for i = 1, length do
            arr[i] = value
        end

        return arr
    end;

    fill = function(self, value, i, j)
        if nil == value then
            error("Cannot add nil into a LuaArray", 2)
        end
        i = i and LuaArray.chkidx(i, self.length, self.length) or 1
        j = j and LuaArray.chkidx(j, self.length, self.length) or self.length
        for o = i, j do
            self[o] = value
        end
        return self
    end;
}

-- 让切片语法更简洁
-- eg: slice = arr(1, 3)
LuaArray.__call = LuaArray.sub

return LuaArray
