# Luaclass

这是一个为 Lua 提供基于类的面向对象编程（Class-based OOP）支持的模块，旨在让 Lua 面向对象编程变得更加简单、优雅，同时功能强大。

## 安装 & 导入

下载模块的主文件夹（[luaclass](https://github.com/blanhhy/luaclass/blob/main/luaclass)）复制到你的 Lua 模块路径。

在 Lua 脚本中使用该模块：

```lua
require "luaclass"
```

模块包含以下接口：

- `luaclass`: metaclass, 相当于 Python 中的 `type`
- `Object`: rootclass, 所有类的基类
- `namespace`: namespacelib, 提供命名空间支持的库
- `decl`: function, 用于声明字段和抽象方法
- `class`: function, 伪关键词, 用于定义类
- `super`: function, 用于调用已经被重写的基类方法
- `isinstance`: function, 用于判断对象是否为某个类实例

正常情况下这些是自动注入到 `_G` 的

## 特性 & 说明

### 1. 快速开始

```lua
require "luaclass"

-- 定义一个类 MyClass
class "MyClass" {
  greet = function(self)
    print("Hello from "..tostring(luaclass(self)));
  end;
}

-- 创建 MyClass 的实例
local obj = MyClass()

-- 调用方法
obj:greet() --> Hello from MyClass
```

### 2. 继承

要继承基类，只需在类名后插入一个括号，就像是在 Python 中做的那样：

```lua
-- 定义一个基类
class "Animal" {
  speak = function(self)
    print(self.name .. " makes a sound.")
  end;
}

-- 定义一个子类
class "Dog"(Animal) -- 继承 Animal 类
{
  __init = function(self, name)
    self.name = name
  end;
  speak = function(self)
    print(self.name .. " barks.")
  end;
}

-- 创建 Dog 类的实例
local dog = Dog("Buddy")
dog:speak() -- 输出: Buddy barks.

-- 调用超类的方法
super(dog):speak() -- 输出: Buddy makes a sound.
```

### 3. 运算符重载

以下代码创建了一个基础的复数类，并用 `__add` 元方法实现了复数的加法：

```lua
-- 定义复数类
class "Complex" {
  __init = function(self, real, imag)
    self.real = real
    self.imag = imag
  end;

  __add = function(a, b)
    return Complex(a.real + b.real, a.imag + b.imag)
  end;

  __tostring = function(self)
    return ("%d + %di"):format(self.real, self.imag)
  end;
}

-- 创建两个复数实例
local z1 = Complex(1, 2)
local z2 = Complex(3, 4)

-- 验证复数加法
print(z1 + z2)  --> 4 + 6i
```

更多示例代码请参见 [demo](https://github.com/blanhhy/luaclass/blob/main/demo)。

## 项目结构

```txt
luaclass/
├── core/
│   ├── checktool.lua
│   ├── creator.lua
│   ├── luaclass.lua
│   ├── namespace.lua
│   └── Object.lua
├── inherit/
│   ├── index.lua
│   ├── isinstance.lua
│   ├── mro.lua
│   └── super.lua
├── share/
│   ├── declare.lua
│   ├── randstr.lua
│   └── weaktbl.lua
├── util/
│   ├── Class.lua
│   ├── Exception.lua
│   ├── LuaArray.lua
│   ├── Range.lua
│   ├── String.lua
│   └── init.lua
├── main.lua
└── init.lua
```

1. `core`：核心模块，包含类定义、基类、元类、命名空间、声明、抽象类、类型检查等功能。
2. `inherit`：继承相关模块，包含计算和利用 MRO 来查找字段、调用方法、判断类型等。
3. `share`：模块级共享模块，包含声明、共享弱表、产生随机类名等功能。
4. `util`：提供给用户的可选工具类，如经典 OOP 风格的 Class, 功能便利的 LuaArray 等。
5. `main.lua`：主入口文件，整理了所有模块的接口。
6. `init.lua`：初始化文件，将模块接口导入到全局环境。

## 反馈

如果你在测试/使用的过程中发现任何问题，请提交 issue 告知我
