require "luaclass"

-- 基础游戏对象类
class "GameObject" {
  __init = function(self, name)
    self.name = name
    self.position = {x=0, y=0}
  end;

  move = function(self, dx, dy)
    self.position.x = self.position.x + dx
    self.position.y = self.position.y + dy
    print(("%s移动到位置(%d, %d)"):format(self.name, self.position.x, self.position.y))
  end;
}

-- 战斗能力类（可被继承）
class "CombatUnit" {
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
class "Player"(GameObject, CombatUnit) {
  __init = function(self, name, hp)
    super(self):__init(name)  -- 调用GameObject的初始化
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
class "Weapon" {
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