function OnSetText(uri, text)
    local diffs = {}

    -- 按行处理，排除单行注释
    local lines = {}
    for line in text:gmatch("[^\n]+") do
        table.insert(lines, line)
    end

    local currentPos = 1
    for i, line in ipairs(lines) do
        -- 检查是否是单行注释
        if not line:match("^%s*%-%-") then

            -- 处理简单情况（无命名空间）：class "ClassName" {
            for classStart, className, beforeBrace in line:gmatch '()class%s+"([%w_]+)"%s*()%{' do
                -- 计算全局位置
                local globalBeforeBrace = currentPos + beforeBrace - 1

                -- 在 { 前插入赋值语句
                diffs[#diffs+1] = {
                    start = globalBeforeBrace,
                    finish = globalBeforeBrace - 1,
                    text = "\n" .. className .. " = "
                }
            end

            -- 处理带继承的情况（无命名空间）：class "ClassName"(Parent) {
            for classStart, className, parents, beforeBrace in line:gmatch '()class%s+"([%w_]+)"%s*%(%s*([%w_,%s]+)%)%s*()%{' do
                -- 计算全局位置
                local globalBeforeBrace = currentPos + beforeBrace - 1

                -- 在 { 前插入赋值语句
                diffs[#diffs+1] = {
                    start = globalBeforeBrace,
                    finish = globalBeforeBrace - 1,
                    text = "\n" .. className .. " = "
                }
            end
        end

        currentPos = currentPos + #line + 1 -- +1 是换行符
    end

    return #diffs > 0 and diffs or nil
end