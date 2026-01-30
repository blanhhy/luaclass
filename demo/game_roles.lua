require "luaclass"

-- 本文件展示命名空间与多继承的综合应用

namespace.new'Game'
namespace.new'Game.Math'

_ENV = namespace.use()
using'Game'
using'lua._G'

-- 游戏地图中的点
class "Game.Math::Point" {
  __init = function(self, x, y)
    self.x, self.y = x or 0, y or 0
  end;

  -- 只定义了本文件中用到的方法, 其他方法暂略

  __add = function(A, B)
    assert(isinstance(B, Math.Point), ("%s不能和%s相加!"):format(A:getClass(), luaclass(B)))
    return Math.Point(A.x + B.x, A.y + B.y)
  end;

  __tostring = function(self)
    return ("(%d, %d)"):format(self.x, self.y)
  end
}

-- 基础游戏对象类
class "Game::GameObject" {
  __init = function(self, name)
    self.name = name
    self.position = Math.Point(0, 0)
  end;

  move = function(self, dx, dy)
    self.position = self.position + Math.Point(dx, dy)
    print(("%s移动到位置%s"):format(self.name, self.position))
  end;
}

-- 战斗能力类（可被继承）
class "Game::CombatUnit" {
  attack = function(self, target)
    print(("%s攻击了%s"):format(self.name, target.name))
  end;

  -- 运算符重载：武器强化攻击
  __add = function(self, weapon)
    local dmg = self.damage + weapon.attack_bonus
    print(("%s装备%s后伤害提升至%d"):format(self.name, weapon.name, dmg))
    return dmg
  end;
}

-- 玩家角色类（多继承）
class "Game::Player" (GameObject, CombatUnit) {
  __init = function(self, name, hp)
    super(self):__init(name) -- 调用父类构造函数
    -- 如果多个父类都有构造函数, 还可以选择想要的版本
    -- super(self, GameObject):__init(name)
    self.hp = hp or 100
    self.damage = 10
  end;

  -- 重写移动方法，改为玩家特殊音效
  move = function(self, dx, dy)
    print(">> 玩家脚步音效 <<")
    super(self):move(dx, dy)  -- 调用父类方法
  end;
}

-- 武器类
class "Game::Weapon" {
  __init = function(self, name, bonus)
    self.name = name
    self.attack_bonus = bonus
  end;
}



-- 创建游戏对象
local sword = Weapon("圣剑", 15)
local hero = Player("勇者", 150)

-- 使用功能
hero:move(5, 3)    --> 玩家特殊移动
hero:attack(sword) --> 基础攻击
local total_damage = hero + sword --> 伤害提升


--[[
输出:
>> 玩家脚步音效 <<
勇者移动到位置(5, 3)
勇者攻击了圣剑
勇者装备圣剑后伤害提升至25
]]