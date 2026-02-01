local outdated  = _VERSION == "Lua 5.1"
local global    = outdated and "_G" or "_ENV"
local defaultns = "lua._G" -- 默认命名空间, 按需修改

---@class diff
---@field start  integer # The number of bytes at the beginning of the replacement
---@field finish integer # The number of bytes at the end of the replacement
---@field text   string  # What to replace

---从指定位置向前查找上一行注释
local function findExtendsComment(text, pos)
    if pos <= 1 then return nil end
    
    -- 从pos-1开始向前搜索换行符
    local lineStart = pos
    
    -- 先向前找到当前行的开始
    for i = pos-1, 1, -1 do
        if text:sub(i, i) == '\n' then
            lineStart = i + 1
            break
        end
        if i == 1 then
            lineStart = 1
        end
    end
    
    -- 再向前找到上一行的开始
    local prevLineStart = lineStart
    for i = lineStart-2, 1, -1 do
        if text:sub(i, i) == '\n' then
            prevLineStart = i + 1
            break
        end
        if i == 1 then
            prevLineStart = 1
        end
    end
    
    if prevLineStart >= lineStart then
        return nil
    end
    
    -- 获取上一行
    local prevLineEnd = lineStart - 1
    if prevLineEnd < prevLineStart then
        return nil
    end
    
    local prevLine = text:sub(prevLineStart, prevLineEnd)
    
    -- 检查是否是---@extends注释
    local extends = prevLine:match("^%s*%-%-%-@extends%s+(.+)$")
    if extends then
        -- 去除两端的空格
        extends = extends:gsub("^%s+", ""):gsub("%s+$", "")
        return extends
    end
    
    return nil
end

---@param  uri  string # The uri of file
---@param  text string # The content of file
---@return diff[]?
function OnSetText(uri, text)
    
    if  not text:find 'require%s*"luaclass"' and
        not text:find "require%s*'luaclass'" and
        not text:find 'require%s*("luaclass")' and
        not text:find "require%s*('luaclass')" then
        return nil
    end

    local diffs = {}
    -- local processed = {} -- 记录已处理的位置，避免重复

    ---无继承情况 class "classname" {}
    for start, classname, finish in text:gmatch '()class%s*"([%w%._]*)"%s*%b{}()' do
        -- if processed[start] then goto continue end
        -- processed[start] = true
        
        local ns_name, name = classname:match("^([^:]-):*([^:]+)$")
        local ns_path

        if not ns_name or ns_name == '' then
            ns_name = defaultns
            ns_path = global
        elseif ns_name:sub(1, 1) == '.' then
            ns_name = defaultns..ns_name -- 相对路径
            ns_path = global..ns_name
        else
            ns_path = "namespace."..ns_name
        end
        
        -- 查找继承注释
        local extends = findExtendsComment(text, start)
        local classAnnotation = "---@class "..ns_name.."."..name
        if extends then
            classAnnotation = classAnnotation.." : "..extends
        else
            classAnnotation = classAnnotation.." : luaclass"
        end

        diffs[#diffs+1] = {
            start = start,
            finish = start - 1,
            text = "(function()\n"..classAnnotation.."\n"..ns_path.."."..name.." = "
        }

        diffs[#diffs+1] = {
            start = finish,
            finish = finish - 1,
            text = "\nreturn "..ns_path.."."..name.." end)()"
        }
        
        -- ::continue::
    end

    ---有继承情况 class "classname" (...) {}
    for start, classname, finish in text:gmatch '()class%s*"([%w%._]*)"%s*%b()%s*%b{}()' do
        -- if processed[start] then goto continue end
        -- processed[start] = true
        
        local ns_name, name = classname:match("^([^:]-):*([^:]+)$")
        local ns_path

        if not ns_name or ns_name == '' then
            ns_name = defaultns
            ns_path = global
        elseif ns_name:sub(1, 1) == '.' then
            ns_name = defaultns..ns_name -- 相对路径
            ns_path = global..ns_name
        else
            ns_path = "namespace."..ns_name
        end
        
        -- 查找继承注释
        local extends = findExtendsComment(text, start)
        local classAnnotation = "---@class "..ns_name.."."..name
        if extends then
            classAnnotation = classAnnotation.." : "..extends
        else
            classAnnotation = classAnnotation.." : luaclass"
        end

        diffs[#diffs+1] = {
            start = start,
            finish = start - 1,
            text = "(function()\n"..classAnnotation.."\n"..ns_path.."."..name.." = "
        }

        diffs[#diffs+1] = {
            start = finish,
            finish = finish - 1,
            text = "\nreturn "..ns_path.."."..name.." end)()"
        }
        
        -- ::continue::
    end

    return #diffs > 0 and diffs or nil
end