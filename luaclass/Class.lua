local luaclass = require "luaclass"

-- 创建一个元类，用于适配lua经典OOP语法
class "Class"(luaclass) {

    ---@Override,@Classmethod
    __new = function(self, name, bases, ns)
        return super(self):__new(name, bases, {namespace = ns or _G})
    end,
}

return Class