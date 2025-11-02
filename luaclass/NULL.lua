--
-- 空值占位符
-- 提供统一的, 带类型的空值占位符, 用于模拟声明变量

-- This file is a part of luaclass library.
-- 注: 本模块专注于提供占位符, 尽管 luaclass 在此基础上实现了初始化变量值时的类型检查, 但那不是主要目的, 只是利用了带类型这一点来顺带开发的功能

local type = type

local NULL_string = {
    type = "string",
    checkType = function(v)return(type(v) == "string")end,
    getDefault = function()return("")end
}

local NULL_number = {
    type = "number",
    checkType = function(v)return(type(v) == "number")end,
    getDefault = function()return(0)end
}

local NULL_boolean = {
    type = "boolean",
    checkType = function(v)return(type(v) == "boolean")end,
    getDefault = function()return(false)end
}

local NULL_table = {
    type = "table",
    checkType = function(v)return(type(v) == "table")end,
    getDefault = function()return{}end
}

local NULL_function = {
    type = "function",
    checkType = function(v)return(type(v) == "function")end,
    getDefault = function()return(function()end)end
}

-- 通用空值, 用于声明变量但不赋值, 类型不限
local NULL_any = {
    type = "any",
    checkType = function(v)return(true)end,
    getDefault = function()return(nil)end
}


return {
    string = NULL_string,
    str = NULL_string,
    s = NULL_string,

    number = NULL_number,
    num = NULL_number,
    n = NULL_number,

    boolean = NULL_boolean,
    bool = NULL_boolean,
    b = NULL_boolean,

    table = NULL_table,
    tbl = NULL_table,
    tb = NULL_table,
    t = NULL_table,

    func = NULL_function,
    fun = NULL_function,
    fn = NULL_function,
    f = NULL_function,

    any = NULL_any,
    val = NULL_any,
    null = NULL_any,

    isNull = {
        [NULL_string] = true,
        [NULL_number] = true,
        [NULL_boolean] = true,
        [NULL_table] = true,
        [NULL_function] = true,
        [NULL_any] = true
    }
}