if not class then
    require "luaclass"
end

local Range_def = {
    ---@Constructor
    __init = function (self, i, j, step)
        if i and not j and not step then
            i, j = 1, i
        end

        i = i or 1
        j = j or i
        step = step or 1

        if not type(i) == "number" then error("bad argument #1, number expected.", 3) end
        if not type(j) == "number" then error("bad argument #2, number expected.", 3) end
        if not type(step) == "number" then error("bad argument #3, number expected.", 3) end

        self.START = i
        self.STOP = j
        self.STEP = step
        self.IS_INCREASE = step > 0

        self._i = i
    end;

    ---@Override
    __tostring = function (self)
        return string.format("Range(%d, %d, %d)", self.START, self.STOP, self.STEP)
    end;

    __len = function (self)
        if not self.length then
            self.length = math.floor((self.STOP - self.START) / self.STEP) + 1
        end
        return self.length
    end;

    next = function (self)
        local current = self._i
        if self.IS_INCREASE == (current > self.STOP) then -- 同或
            return nil
        end
        self._i = current + self.STEP
        return current
    end;

    wind = function (self)
        self._i = self.START
        return self
    end
}

-- 确保能被 for 直接调用
Range_def.__call = Range_def.next

return luaclass("lua.class::Range", nil, Range_def)