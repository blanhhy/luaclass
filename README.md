# Luaclass

这是一个为 Lua 提供基于类的面向对象编程（Class-based OOP）支持的模块，旨在让 Lua 面向对象编程变得更加简单、优雅，同时功能强大。

## 安装 & 导入

下载模块的主文件夹（[luaclass](https://github.com/blanhhy/luaclass/blob/main/luaclass)）并导入你的 Lua 模块路径。

> 如果你使用 Android 上的 Fusion App2 的话，可以从 [Github 发布页](https://github.com/blanhhy/luaclass/releases) 下载专用版本。

在 Lua 脚本中使用该模块：

```lua
require "luaclass"
```

导入后，模块会自动向 _G 中注入以下内容：

- `luaclass`: metaclass
- `Object`: rootclass
- `namespace`: namespacelib
- `decl`: function
- `class`: function
- `super`: function
- `isinstance`: function

## 特性 & 说明

### 1. 快速开始

```lua
require "luaclass"

-- 定义一个全局类 MyClass
class "_G::MyClass" {
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
class "_G::Animal" {
  speak = function(self)
    print(self.name .. " makes a sound.")
  end;
}

-- 定义一个子类
class "_G::Dog"(Animal) -- 继承 Animal 类
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
class "_G::Complex" {
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

## 更新日志

### v1.8

- 使用完整，独立的命名空间管理模块，带来全新理念
- 现在类定义时要在类名中指定命名空间，否则隐式指定为 `class::YourClass`
- 新增带类型的声明占位符，可增加自定义类型
- 新增声明模式，检查字段是否正确初始化为声明的类型
- 新增 `Object` 基类，提供 `getClass` `isInstanceOf` `toString` 方法
- 项目结构优化，拆分文件职能，内部细节优化
- 附加可选的经典语法适配类 `Class` 和字符串适配类 `String`
- 新增一些demo代码，配有详细的注释
- 修复了一些已知问题

### v1.7

- 更新元类与命名空间相关支持
- 修复元方法无法继承的问题
- 优化内部实现逻辑与性能

### v1.6

- 再次更新语法，新的语法更加清新可读
- 优化了类的创建逻辑，弃用了原来切换环境的方案，并提高内部代码复用性
- 为 `super` 函数的调用结果加入了缓存机制
- 现在发生单调性冲突时，会拒绝创建类
- 新增了 `isinstance` 函数

详细更新请查阅 [更新日志](https://github.com/blanhhy/luaclass/blob/main/changelog.md)。

## 可能的新功能

更新构想，不代表一定会实现

- **__list缓存**：动态缓存缓存类的属性和方法，方便调试。
- **私有成员**: 引入一个私有成员的储存机制，增强对象封装性。
- **继承基本类**: 允许继承 Lua 基本类型。

## 反馈

如果你在测试/使用的过程中发现任何问题，请提交 issue 告知我
