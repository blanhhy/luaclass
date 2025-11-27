local tostring = tostring
local tochar = string.char
local concat = table.concat
local time, clock = os.time, os.clock
local random, randseed = math.random, math.randomseed

local function randstring(len)
    randseed(tostring(clock()*1000):sub(-5, -3)*tostring(time()):sub(-4):reverse())
    local res = {}
    for i = 1,len do
        res[i] = tochar(random(48, 122)) -- 字母或数字
    end
    return concat(res)
end

return randstring