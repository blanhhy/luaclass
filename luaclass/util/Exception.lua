if not luaclass then
    require "luaclass"
end

---@class _G
local _G, type, select, isinstance
    = _G, type, select, isinstance

_G.throw = _G.error

class "Exception" {
    fmt = "%s: %s";
    msg = "An error occurred";
--  tag = decl.table;

    __init = function(self, msg)
        self.msg = msg or self.msg
    end;

    __tostring = function(self)
        return self.fmt:format(self.__class, self.msg)
    end;

    set_msg = function(self, msg)
        self.msg = msg
        return self
    end;

    format = function(self, ...)
        self.msg = self.msg:format(...)
        return self
    end;

    attach = function(self, ...)
        local tags = {...}
        if not self.tag then
            self.tag = tags
            return self
        end
        local tag = self.tag
        local len = #tag
        for i = 1, len do
            tag[len+i] = tags[i]
        end
        return self
    end;

    throw = _G.error;
}

class "TypeError"(Exception) {
    msg = "";

    __init = function(self, ...)
        if not (...) then return end
        
        if select("#", ...) > 1 then
            return self:__init_args(...)
        end
        
        local typ = type(...)
        
        if     typ == "number" then return self:__init_args(...)
        elseif typ == "table"  then return self:__init_kvargs(...)
        elseif typ == "string" then self.msg = (...)
        end
    end;

    __init_kvargs = function(self, kvargs)
        if kvargs.msg then
            self.msg = kvargs.msg
            return
        end
        if not kvargs.actual and kvargs.got then
            kvargs.actual = isinstance(kvargs.got)
        end
        return self:__init_args(
            kvargs.pos,
            kvargs.expected,
            kvargs.actual)
    end;

    __init_args = function(self, pos, expected, actual)
        self.pos      = pos
        self.expected = expected
        self.actual   = actual

        self.msg = "bad argument"

        if pos      then self.msg = self.msg.. (" #%d"):format(pos) end
        if expected then self.msg = self.msg.. (", %s expected"):format(expected) end
        if actual   then self.msg = self.msg.. (", got %s"):format(actual) end
        
        self.msg = self.msg.. "."
    end;
}

return Exception