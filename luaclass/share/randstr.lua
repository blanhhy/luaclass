local char = string.char
local rand, setseed = math.random, math.randomseed
local concat = table.concat

-- 字符集定义
local charset = {}
local char_count = 0

-- 0-9
for i = 48, 57 do
  char_count = char_count + 1
  charset[char_count] = char(i)
end
-- A-Z
for i = 65, 90 do
  char_count = char_count + 1
  charset[char_count] = char(i)
end
-- a-z
for i = 97, 122 do
  char_count = char_count + 1
  charset[char_count] = char(i)
end

local inited = false

-- 初始化种子
local function initseed()
  local seed = tonumber(tostring(math.floor(os.time()*1e4+os.clock()*1e6)):reverse())
             * tonumber("0x"..tostring(charset):sub(10))
  setseed(seed)
  for _=1,10 do rand() end -- 预热
  inited = true
end

-- 生成定长随机字符串
local function randstring(len)
  if not inited then initseed() end
  local chars = {}
  for i = 1, len do
    chars[i] = charset[rand(1, char_count)]
  end
  return concat(chars)
end

return randstring