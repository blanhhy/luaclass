-- 不同方式创建class演示
class "my"
a = 10
function hh(self, t)
  t = t or self.a
  print(self.__classname.."调用了超类方法"..t)
end
local my = class()

local your = luaclass("your", {
  a = 20,
  hh = function(self, t)
    print(self.__classname.."调用了子类方法"..t)
  end
}, my)

class "your2"
function hh(self, t)
  super():hh(t)
  print(self.__classname.."调用了子类方法"..t)
end
local your2 = class(my)


printf(my:__list())
-- >{ __classname, __type, __list, __tostring, __index, hh }

super(your):hh()
-- >your调用了超类方法20

your2:hh(7)
-- >your2调用了超类方法7
-- >your2调用了子类方法7

-- -- -- --

-- 多次继承与实例化演示
class "myFirstClass"
name = "李华"
function __init(self, age)
  if age then
    self.age = age
   else
    self.age = 12
  end
end
function speak(self)
  print(self.name.."，"..self.age.."岁")
end
local myFirstClass = class()
-- 定义myFirstClass

class "mySecondClass"
name = "小明"
function setRelationship(self)
  return "爸", 0
end
function speak(self)
  local relationship, agegap = self.setRelationship()
  print("我叫"..self.name.."，今年"..tostring(self.age+agegap).."岁")
end
local mySecondClass = class(myFirstClass)
-- 继承超类myFirstClass，并覆写name属性和speak方法

class "myThirdClass"
function setRelationship(self)
  return "爸", 20
end
function speak(self)
  local relationship, agegap = self.setRelationship(self)
  print("我是"..self.name.."他"..relationship.."，今年"..tostring(self.age+agegap).."岁")
end
local myThirdClass = class(mySecondClass)
-- 继承超类mySecondClass，并覆写speak方法

local vvv = myThirdClass(8)
local uuu = mySecondClass(8)
local www = myFirstClass(16)
-- 创建一些实例

vvv:speak()
-- >我是小明他爸，今年28岁

super(vvv):speak() -- 调用超类的speak方法
-- >我叫小明，今年28岁

uuu:speak()
-- >我叫小明，今年8岁

www:speak()
-- >李华，16岁
