myFirstClass = class({
  name = "李华",
  __init__ = function(self, age)
    if age then
      self.age = age
     else
       self.age = 12
    end
  end,
  speak = function(self)
    print(self.name.."，"..self.age.."岁")
  end,
})--定义myFirstClass


mySecondClass = class({
  name = "小明",
  setRelationship = function(self)
    return "爸", 0
  end,
  speak = function(self)
    local relationship, agegap  =  self.setRelationship(self)
    print("我叫"..self.name.."，今年"..tostring(self.age+agegap).."岁")
  end,
},
myFirstClass
)--继承父类myFirstClass，并覆写name属性和speak方法


myThirdClass = class({
  setRelationship = function(self)
    return "爸", 20
  end,
  speak = function(self)
    local relationship, agegap  =  self.setRelationship(self)
    print("我是"..self.name.."他"..relationship.."，今年"..tostring(self.age+agegap).."岁")
  end,
},
mySecondClass
)--继承父类mySecondClass，并覆写speak方法


local vvv = myThirdClass(8)
local uuu = mySecondClass(8)
local www = myFirstClass(16)
--创建实例


vvv.speak(vvv)
--返回：我是小明他爸，今年28岁

super(vvv).speak(vvv)
--调用父类的speak方法
--返回：我叫小明，今年28岁

uuu.speak(uuu)
--返回：我叫小明，今年8岁

www.speak(www)
--返回：李华，16岁