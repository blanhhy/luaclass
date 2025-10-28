local luaclass = require "luaclass"

-- define the Object class
class "Object" {
    __init = function(self, cls, args)
    end,
    __tostring = function(self)
        return ("<%s object>"):format(self.__class.__classname)
    end
}