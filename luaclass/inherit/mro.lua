--
-- This file is a part of luaclass library.


-- 合并基类的 MRO
return function (cls, bases)
  if not bases or not bases[1] then
    return {cls, n = 1, lv = {1, n = 1}}
  end

  local mro                      = {cls}  -- 结果MRO
  local mroLength                = 1      -- 结果MRO长度
  local mroLengthEachLevels      = {1}    -- 结果MRO的每一层长度

  local baseCount                = #bases -- 基类数量
  local baseMROs                 = {}     -- 各基类的MRO
  local baseMROsLength           = {}     -- 各基类的MRO长度
  local MROsNextIndextoMerge     = {}     -- 各基类MRO的合并进度
  local baseMROsLengthEachLevels = {}     -- 储存每个基类的MRO中每一层长度的二维表

  local maxDepth                 = 0      -- 最大继承深度
  local seenClassesPos           = {}     -- 合并过程中已出现过的类位置
  local minConflictPos           = 0      -- 最小冲突位置

  --[[
    最小冲突位置, 动态更新, 冲突位置大于这个值就向后归并, 但不得小于这个值
    冲突位置, 指的是线性化过程中, 出现了两个相同的类, 前面那个类的位置就是冲突位置
  ]]

  -- 准备工作：从基类中获取各自的MRO和长度，并计算最大继承深度
  for i = 1, baseCount do
    local base = bases[i]
    local baseMRO = base.__mro

    -- 获取每个基类的MRO和长度
    baseMROs[i] = baseMRO
    baseMROsLength[i] = baseMRO.n
    MROsNextIndextoMerge[i] = 1 -- 还没有开始合并, 所以下一个位置是1

    -- 获取每个基类的MRO中每一层长度的信息
    local baseMROLengthEachLevels = baseMRO.lv
    baseMROsLengthEachLevels[i] = baseMROLengthEachLevels

    -- 计算最大继承深度
    local baseMRO_Depth = baseMROLengthEachLevels.n -- 继承深度, 就是MRO的层级数
    maxDepth = baseMRO_Depth >= maxDepth
      and baseMRO_Depth
      or maxDepth
  end

  -- 声明一些局部变量
  local currMRO             -- 当前正在处理的MRO
  local classGroupCount     -- 组数量：当前MRO在当前层级中包含的超类数量
  local currMROLength       -- 当前MRO长度
  local nextIndextoMerge    -- 当前MRO在开始合并这一层时, 应该从这个位置开始
  local nextIndexonMerged   -- 预计在合并完这一层之后, 下次应该从这个位置开始
  local currClass           -- 当前正在处理的超类
  local pos                 -- 当前超类在结果MRO中的位置

  -- 对于每个基类, 遍历它们的MRO的每个层级, 处理其中的一组超类
  for whichLevel = 1, maxDepth do
    local mergedCountInLevel = 0 -- 记录当前层级实际合并的超类数量
    for whichBase = 1, baseCount do

      currMRO = baseMROs[whichBase]
      classGroupCount = baseMROsLengthEachLevels[whichBase][whichLevel]

      if classGroupCount then
        local currMROLength = baseMROsLength[whichBase]
        local nextIndextoMerge = MROsNextIndextoMerge[whichBase]
        local nextIndexonMerged = nextIndextoMerge + classGroupCount

        -- 开始合并当前定位到的超类组
        for i = nextIndextoMerge, nextIndexonMerged - 1 do
          currClass = currMRO[i]

          -- 如果当前类没有出现过, 直接加入结果MRO中
          if not seenClassesPos[currClass] then
            pos = mroLength + 1

            mro[pos] = currClass -- 加入结果MRO中
            seenClassesPos[currClass] = pos -- 记录这个类在结果中的位置

            mergedCountInLevel = mergedCountInLevel + 1 -- 计算当前层级合并的超类数量
            mroLength = mroLength + 1 -- 记录的长度 +1

          else
            -- 如果当前超类已经出现过, 则需要处理可能的冲突
            local currClassSeenPos = seenClassesPos[currClass] -- 查询这个类之前出现过的位置
            --[[
              单调性错误：
              当 currClassSeenPos < minConflictPos 的时候, 就发生了单调性错误
              为什么是这个条件？比如说：A -> B -> C -> B -> A 这个处理过程
              其中 B -> C -> B 是允许的, 尽管B重复了, 但可以合并, 不影响单调性
              这时候记录 minConflictPos = 2, 也就是第一个B的位置, 然后后面就不能再出现2之前的类了
              处理到最后面的A的时候, 发现它已经出现过, 并且 currClassSeenPos = 1, 所以A是不允许的
              直观的理解就是：前面的 A -> B 和后面的 B -> A 冲突了, 无法确认A和B哪个在前哪个在后
            ]]
            if currClassSeenPos < minConflictPos then -- 发生错误

              -- 放弃合并, 收集信息, 构造错误提示
              local errMsg = "Cannot create class '%s' due to MRO conflict. (in bases: %s, %s)\n"
                          .. "Processing traceback:\n"
                          .. "    [ %s ]\n"
                          .. "    interrupt at MRO of superclass '%s', level #%d\n"

              local tostring, concat = _G.tostring, _G.table.concat

              local lastConflictPos   = minConflictPos      -- 上一个冲突位置
              local currConflictPos   = currClassSeenPos    -- 最新冲突位置
              local lastConflictClass = mro[minConflictPos] -- 发生冲突的类
              local currConflictClass = currClass           -- 引发冲突的类
              local whichChain        = bases[whichBase]    -- 冲突所在的链
              local whichLevel        = whichLevel          -- 冲突所在的层级

              local mergedMROPath = (function()
                local str_list = {cls.__classname}
                for i = 2, #mro do
                  str_list[i] = tostring(mro[i])
                    .. (mro[i] == lastConflictClass and ("@"..lastConflictPos)
                    or  mro[i] == currConflictClass and ("@"..currConflictPos)
                    or  "")
                end
                local count = #str_list
                str_list[count+1] = tostring(lastConflictClass)..("@"..(count+1))
                str_list[count+2] = tostring(currConflictClass)..("@"..(count+2))
                return concat(str_list, " -> ")
              end)() -- 已知的 MRO 路径

              return nil,
              errMsg:format(
                cls.__classname,
                lastConflictClass,
                currConflictClass,
                mergedMROPath,
                whichChain,
                whichLevel
              )
            end
            -- 不满足错误条件, 允许冲突, 但不加入MRO, 因为已经存在
            minConflictPos = currClassSeenPos -- 更新最小冲突位置
          end
        end
        -- 更新当前基类的MRO合并进度
        MROsNextIndextoMerge[whichBase] = nextIndexonMerged
      end
    end
    -- 记录当前层级合并的超类数量
    mroLengthEachLevels[whichLevel + 1] = mergedCountInLevel
  end
  mro.n = mroLength -- 记录结果MRO长度
  mroLengthEachLevels.n = 1 + maxDepth -- 记录结果MRO的每一层长度
  mro.lv = mroLengthEachLevels -- 记录结果MRO的每一层长度
  return mro
end
