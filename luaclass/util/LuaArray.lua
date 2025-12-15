-- luaclass/util/LuaArray.lua
-- 这个类需要单独导入, require "luaclass" 的时候并不会包含luaclass.util.*

if not class then
    require "luaclass"
end

local type = type
local tostring = tostring
local Int = math.floor
local remove = table.remove

class "LuaArray" {
    ---@static
    chkidxEnabled = true;

    ---@static
    ---@param lim integer
    ---@return integer index
    chkidx = function(index, lim)
        if not LuaArray.chkidxEnabled then return index end
        local err = (
            (type(index) ~= "number" or Int(index) ~= index) and
            ("<integer> expected, got <%s>."):format(isinstance(index))
        ) or (
            (index < 1 or index > lim) and
            "Array index out of range"
        )
        if err then error(err, 3) end
        return index
    end;

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

    __len = function(self)
        return self.length
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

    ---@param index integer
    insert = function(self, index, value)
        index = LuaArray.chkidx(index, self.length + 1)
        if nil == value then
            error("Cannot add nil into a LuaArray", 2)
        end
        self.length = self.length + 1
        return table.insert(self, index, value)
    end;

    ---@param index integer
    pop = function(self, index)
        index = LuaArray.chkidx(index, self.length)
        local value = remove(self, index)
        self.length = self.length - 1
        return value
    end;

    find = function(self, value)
        if nil == value then
            error("non-nil value expected.", 2)
        end
        for i = 1, self.length do
            if value == self[i] then return i end
        end
        return nil
    end;

    findLast = function(self, value)
        if nil == value then
            error("non-nil value expected.", 2)
        end
        for i = self.length, 1, -1 do
            if value == self[i] then return i end
        end
        return nil
    end;

    findAll = function(self, value)
        if nil == value then
            error("non-nil value expected.", 2)
        end
        local indexs = LuaArray:__new()
        local count = 0
        for i = 1, self.length do
            if value == self[i] then
                count = count + 1
                indexs[count] = i
            end
        end
        indexs.length = count
        return indexs
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

    ---@param array table
    extend = function(self, array)
        if type(array) ~= "table" then
            error(("<table?> expected, got <%s>."):format(isinstance(array)), 2)
        end
        local length = self.length
        local count = 0
        for i, v in ipairs(array) do
            self[length + i] = array[i]
            count = i
        end
        self.length = length + count
    end;

    ---@param i? integer
    ---@param j? integer
    reverse = function(self, i, j)
        i = i and LuaArray.chkidx(i, self.length) or 1
        j = j and LuaArray.chkidx(j, self.length) or self.length
        while i < j do
            self[i], self[j] = self[j], self[i]
            i = i + 1
            j = j - 1
        end
        return self
    end;

    ---@param i? number
    ---@param j? number
    ---@param step? number
    sub = function(self, i, j, step)
        i = i and (type(i)=="number" and i or error("<number?> expected", 2)) or 1
        j = j and (type(j)=="number" and j or error("<number?> expected", 2)) or self.length
        step = step and (type(step)=="number" and step or error("<number?> expected", 2)) or 1

        if i < 0 then i = self.length + 1 + i end
        if j < 0 then j = self.length + 1 + j end

        local slice = LuaArray:__new() -- 内部构造函数, 为了下面手动初始化
        local count = 0

        for o = i, j, step do
            count = count + 1
            slice[count] = self[o]
        end

        slice.length = count

        return slice
    end;

    -- 获取值的集合, 顺便包含第一次出现的索引
    values = function(self)
        local values = {}
        for i = self.length, 1, -1 do
            values[self[i]] = i
        end
        return values
    end;
}

-- 让切片语法更简洁
-- eg: slice = arr(1, 3)
LuaArray.__call = LuaArray.sub

return LuaArray
