-- 基本函数与语法演示
local my = class "my" -- 定义一个局部类
a = 10
function hh(self, t)
  t = t or self.a
  print(self.__classname.."调用了超类方法"..t)
end
function gg(self)
  if _G[self.__classname] then
    print("这是一个全局类！")
   else
    print("这是一个局部类！")
  end
end
class.end() -- 结束创建类

-- 动态地创建一个类
local your = luaclass("your", {
  a = 20,
  hh = function(self, t)
    print(self.__classname.."调用了子类方法"..t)
  end
}, my)

your2 = class("your2",my) --定义一个全局类
function hh(self, t)
  super():hh(t) -- 在类方法中调用超类方法时，无需传递任何参数
  print(self.__classname.."调用了子类方法"..t)
end
class.end()


printf(my:__list())
-- >{ __classname, __type, __list, __tostring, __index, hh }

super(your):hh()
-- >your调用了超类方法20

your2:hh(7)
-- >your2调用了超类方法7
-- >your2调用了子类方法7

my:gg() -- >这是一个局部类！
your2:gg() -- >这是一个全局类！


-- -- -- --


-- 多次继承与实例化演示
-- 定义myFirstClass
local myFirstClass = class "myFirstClass"
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
class.end()

-- 继承超类myFirstClass，并覆写name属性和speak方法
local mySecondClass = class("mySecondClass", myFirstClass)
name = "小明"
function setRelationship(self)
  return "爸", 0
end
function speak(self)
  local relationship, agegap = self.setRelationship()
  print("我叫"..self.name.."，今年"..tostring(self.age+agegap).."岁")
end
class.end()

-- 继承超类mySecondClass，并覆写speak方法
local myThirdClass = class("myThirdClass",mySecondClass)
function setRelationship(self)
  return "爸", 20
end
function speak(self)
  local relationship, agegap = self.setRelationship(self)
  print("我是"..self.name.."他"..relationship.."，今年"..tostring(self.age+agegap).."岁")
end
class.end()

-- 创建一些实例
local vvv = myThirdClass(8)
local uuu = mySecondClass(8)
local www = myFirstClass(16)

vvv:speak()
-- >我是小明他爸，今年28岁

super(vvv):speak() -- 调用超类的speak方法
-- >我叫小明，今年28岁

uuu:speak()
-- >我叫小明，今年8岁

www:speak()
-- >李华，16岁