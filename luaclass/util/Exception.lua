if not luaclass then
    require "luaclass"
end

_G.throw  = error
_G.try    = pcall
_G.trycat = xpcall

class "Exception" {
    fmt = "%s: %s";
    msg = "An error occurred";

    __init = function(self, msg)
        self.msg = msg or self.msg
    end;

    __tostring = function(self)
        return self.fmt:format(self:getClass(), self.msg)
    end;
}

class "ArgException"(Exception) {
    msg = "bad argument";

    __init = function(self, ...)
        if not (...) then return end
        local nargs = select("#",...)
        if nargs > 1 then
            return self:__init_args(...)
        end
        local typ = type(...)
        if typ == "number" then
            return self:__init_args(...)
        elseif typ == "table" then
            return self:__init_kvargs(...)
        elseif typ == "string" then
            self.msg =...
        end
    end;

    __init_kvargs = function(self, kvargs)
        if kvargs.msg then
            self.msg = kvargs.msg
            return
        end
        local pos, expected, actual = kvargs.pos, kvargs.expected, kvargs.actual
        if kvargs.got then actual = isinstance(kvargs.got) end
        self:__init_args(pos, expected, actual)
    end;

    __init_args = function(self, pos, expected, actual)
        self.pos = pos
        self.expected = expected
        self.actual = actual
        if pos then self.msg = self.msg.. (" #%d"):format(pos) end
        if expected then self.msg = self.msg.. (", %s expected"):format(expected) end
        if actual then self.msg = self.msg.. (", got %s"):format(actual) end
        self.msg = self.msg.. "."
    end;
}

return Exception