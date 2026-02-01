---@meta

---@alias MenberReceiver fun(tbl:table):luaclass

---类创建器, 用于处理语法  
---一个完整的示例如下: 
---```lua
---class "Myclass" (base1, base2, ...) {
---    static_field = value;
---    static_method = function(arg1, arg2)
---        -- do something
---    end;
---    __init = function(self, arg1, arg2)
---        -- do something
---    end;
---    method = function(self, arg1, arg2)
---        -- do something
---    end;
---}
---```
---其中 ```(base1, base2, ...)``` 是可选的结构
---
---@param name? string
function class(name)
    ---@overload fun(tbl:table):luaclass
    ---@overload fun(...):MenberReceiver
    return function(...) end
end