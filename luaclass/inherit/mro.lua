-- luaclass/inherit/mro.lua
-- This file is a part of luaclass library.

local _G = _G

--[[
分块线性化算法（Block Linearization Algorithm）
广度优先, 尊重基类声明顺序, 保持单调性
具体来说, 就是将每个基类的 MRO 按层级进行分块, 然后逐层合并这些分块
]]

---方法解析顺序表, 带长度和每层长度信息
---@alias MRO {[integer]: luaclass, n: integer, lv: {[integer]: integer, n: integer}}

---合并基类的 MRO
---@param cls   luaclass
---@param bases luaclass[]
---@return MRO?, string? errMsg
return function (cls, bases)
  if not bases or not bases[1] then
    return {cls, n = 1, lv = {1, n = 1}}
  end

  local res_mro    = {cls} -- 结果MRO
  local res_length = 1     -- 结果MRO长度
  local res_lvsize = {1}   -- 结果MRO的每一层长度
  local res_nlevel = 1     -- 结果MRO的层数
  local next_index = {}    -- 各基类MRO的合并进度
  local seen_pos   = {}    -- 合并过程中已出现过的类位置

  local minConflictPos = 0 -- 最小冲突位置

  --[[
    最小冲突位置, 动态更新, 冲突位置大于这个值就向后归并, 但不得小于这个值
    冲突位置, 指的是线性化过程中, 出现了两个相同的类, 前面那个类的位置就是冲突位置
  ]]

  for level_i = 1, 100 do -- 最大循环100次 (不会有这么深的继承)
    local merged_count = 0 -- 记录这一层实际合并的数量
    
    for base_i = 1, #bases do
      local curr_mro = bases[base_i].__mro
      local block_size = curr_mro.lv[level_i]

      next_index[base_i] = next_index[base_i] or 1

      if block_size then
        local index_to_merge = next_index[base_i]
        local index_on_merged = index_to_merge + block_size

        -- 开始合并当前定位到的块
        for i = index_to_merge, index_on_merged - 1 do
          local curr_cls = curr_mro[i]

          -- 如果当前类没有出现过, 直接加入结果MRO中
          if not seen_pos[curr_cls] then
            local pos = res_length + 1

            res_mro[pos] = curr_cls -- 加入结果MRO中
            seen_pos[curr_cls] = pos -- 记录这个类在结果中的位置

            merged_count = merged_count + 1 -- 计算当前层级合并的超类数量
            res_length = res_length + 1 -- 记录的长度 +1

          else
            -- 如果当前超类已经出现过, 则需要处理可能的冲突
            local conflict_pos = seen_pos[curr_cls] -- 查询这个类之前出现过的位置
            --[[
              单调性错误：
              当 currClassSeenPos < minConflictPos 的时候, 就发生了单调性错误
              为什么是这个条件？比如说：A -> B -> C -> B -> A 这个处理过程
              其中 B -> C -> B 是允许的, 尽管B重复了, 但可以合并, 不影响单调性
              这时候记录 minConflictPos = 2, 也就是第一个B的位置, 然后后面就不能再出现2之前的类了
              处理到最后面的A的时候, 发现它已经出现过, 并且 currClassSeenPos = 1, 所以A是不允许的
              直观的理解就是：前面的 A -> B 和后面的 B -> A 冲突了, 无法确认A和B哪个在前哪个在后
            ]]
            if conflict_pos < minConflictPos then -- 发生错误

              -- 放弃合并, 收集信息, 构造错误提示
              local errMsg = "Cannot create class '%s' due to MRO conflict. (in bases: %s, %s)\n"
                          .. "Processing traceback:\n"
                          .. "    [ %s ]\n"
                          .. "    interrupt at MRO of superclass '%s', level #%d\n"

              local tostring, concat = _G.tostring, _G.table.concat

              local prev_seen_pos = minConflictPos
              local curr_seen_pos = conflict_pos
              local prev_cls = res_mro[minConflictPos] -- 发生冲突的类
              
              local merged_path = (function()
                local str_list = {cls.__classname}
                for i = 2, #res_mro do
                  str_list[i] = tostring(res_mro[i])
                    .. (res_mro[i] == prev_cls and ("@"..prev_seen_pos)
                    or  res_mro[i] == curr_cls and ("@"..curr_seen_pos)
                    or  "")
                end
                local count = #str_list
                str_list[count+1] = tostring(prev_cls)..("@"..(count+1))
                str_list[count+2] = tostring(curr_cls)..("@"..(count+2))
                return concat(str_list, " -> ")
              end)() -- 已知的 MRO 路径

              return nil, errMsg:format(
                cls.__classname,
                prev_cls,
                curr_cls,
                merged_path,
                bases[base_i],
                level_i
              )
            end
            -- 不满足错误条件, 允许冲突, 但不加入MRO, 因为已经存在
            minConflictPos = conflict_pos -- 更新最小冲突位置
          end
        end
        -- 更新当前基类的MRO合并进度
        next_index[base_i] = index_on_merged
      end
    end
    
    -- 实际合并数为0代表已经结束
    if merged_count == 0 then
      break
    end

    res_lvsize[level_i + 1] = merged_count
    res_nlevel = res_nlevel + 1
  end

  res_mro.n = res_length
  res_lvsize.n = res_nlevel
  res_mro.lv = res_lvsize

  return res_mro
end
