local declare    = require "luaclass.share.declare"
local isinstance = require "luaclass.inherit.isinstance"

local next, type = next, type

-- 获取类的声明字段表
local function getDeclared(clstb, bases)
  local declared = {}

  -- 合并所有基类的声明
  if bases then
    for i = 1, #bases do
      if bases[i].__declared then
        for k, v in next, bases[i].__declared do
          declared[k] = v
        end
      end
    end
  end

  -- 添加当前类的声明
  for k, v in next, clstb do
    if declare.type[v] then
      declared[k] = v
    end
  end

  return declared
end

-- 获取类的抽象方法列表
local function getAbstractMethods(clstb, bases)
  clstb.__declared = clstb.__declared or getDeclared(clstb, bases)
  local abms = {}
  local method = declare.method
  for k, v in next, clstb.__declared do
    if v == method then abms[#abms + 1] = k end
  end
  return abms
end

-- 检查所有声明字段是否正确初始化
local function isInitialized(cls, inst)
  local declared = cls.__declared -- 所有声明字段
  local decltype = declare.type   -- 获取声明类型
  local value    = nil
  for field, decl in next, declared do
    value = inst[field]
    if nil == value then -- 未初始化
      return false, ("Uninitialized declared field '%s' in instance of class '%s'")
        :format(field .. ": " .. decltype[decl], cls.__classsgin)
    end
    if not isinstance(value, decltype[decl]) then -- 类型不匹配
      return false, ("Initializing declared field '%s' with a %s value in instance of class '%s'")
        :format(field .. ": " .. decltype[decl], isinstance(value), cls.__classsgin)
    end
  end
  return true
end

-- 检查是否实现所有抽象方法
local function isImplemented(cls, bases)
  local abms, method
  for i = 1, #bases do
    abms = bases[i].__abstract_methods
    if abms then
      for j = 1, #abms do
        method = cls[abms[j]]
        if method == declare.method or type(method) ~= "function" then
          return false, ("class '%s' is not abstract and does not override abstract method '%s'")
            :format(cls.__classsgin, abms[j])
        end
      end
    end
  end
  return true
end



return {
  getDeclared        = getDeclared,
  getAbstractMethods = getAbstractMethods,
  isInitialized      = isInitialized,
  isImplemented      = isImplemented,
}
