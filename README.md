# Luaclass

**Luaclass** 是一个为 Lua 提供面向对象编程（OOP）支持的模块，轻量但功能强大，支持多继承、方法解析顺序（MRO）计算、动态类创建、超类方法调用缓存等特性。该模块提供了一种直观的方式来定义类、继承基类，并灵活管理类的属性和方法，使 Lua 的面向对象编程更加优雅。

## 特色

- **简洁的语法**：声明式的定义语法，简洁清新，支持 `class "Name" {}` ，也支持 `class.Name {}` 。
- **自动实例化**：熟悉的实例化语法 (`obj = MyClass()`) ，无需像 Lua 的传统 OOP 方案那样手动调用 `new()` 方法。
- **多继承支持**：采用 `MRO` 机制，自动解析方法调用顺序，解决菱形继承问题。
- **兼容 Lua 元方法**：用特殊方法 `__init` 方法来初始化对象，除此之外， `__add`、`__tostring`、`__call` 等绝大多数 Lua 元方法都能作为特殊方法、控制对象的行为。
- **超类方法调用**：使用 `super(cls_or_obj)` 函数，以对象或子类的身份访问超类的属性和方法。
- **对象类型判断**：使用 `isinstance(obj, cls)` 函数，方便地判断对象是否是某个类（或者它的子类）的实例。

## 依赖项

本模块依赖于 [packagex](https://github.com/blanhhy/packagex) 和 [tablex](https://github.com/blanhhy/tablex) 模块。

具体依赖的函数请点击 [这里](https://github.com/blanhhy/luaclass/blob/main/requirement.md) 来查看。

## 安装

只需要下载模块的主文件（[luaclass.lua](https://github.com/blanhhy/luaclass/blob/main/luaclass.lua)）并将其导入到 Lua 项目中来安装 **Luaclass**。

如果你使用 Android 上的 Fusion App2 的话，可以从 [Github 发布页](https://github.com/blanhhy/luaclass/releases) 下载专用版本。

在 Lua 脚本中使用该模块，只需像这样导入：

```lua
require "luaclass"
```

需要注意的是，这里导入的 `luaclass` 是一个类，而模块真正导出的可用函数是 `class` ,  `super` 和 `isinstance` 。

## 演示

### 1. 基础示例

以下是一个基础的使用示例：

```lua
-- 定义一个类 "MyClass"
class "MyClass" {
  greet = function(self)
    print("Hello from " .. type(self));
  end;
}

-- 创建 MyClass 的实例
local obj = MyClass()

-- 调用方法
obj:greet() --> Hello from MyClass
```

或者如果你喜欢的话，也可以这么写：

```lua
class.MyClass {
  greet = function(self)
    print("Hello from " .. type(self));
  end;
}
```

### 2. 继承示例

要继承基类，只需在类名后插入一个括号，就像是在 C++ 或者 Python 中做的那样：

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

### 3. 元方法示例

以下代码创建了一个复数类，并用 `__add` 元方法实现了复数的加法：

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
    return string.format("%d + %di", self.real, self.imag)
  end;
}

-- 创建两个复数实例
local z1 = Complex(1, 2)
local z2 = Complex(3, 4)

-- 验证复数加法
print(z1 + z2)  --> 4 + 6i
```

更多示例请参见 [demo](https://github.com/blanhhy/luaclass/blob/main/demo.lua)。

## 更新日志

### v1.6

- 再次更新语法，新的语法更加清新可读
- 优化了类的创建逻辑，弃用了原来切换环境的方案，并提高内部代码复用性
- 为 `super` 函数的调用结果加入了缓存机制
- 现在发生单调性冲突时，会拒绝创建类
- 新增了 `isinstance` 函数

### v1.5

- 加入 `MRO` 机制，全面支持多继承
- `__list` 方法被暂时废弃，后续更新会重新加入

### v1.4
- 统一了超类方法调用语法 (`super(cls_or_obj):method()`)
- 改进了类创建语法，现在创建类更加优雅
- 修复了 `super` 函数的性能问题并改善了缓存机制

详细更新请查阅 [更新日志](https://github.com/blanhhy/luaclass/blob/main/changelog.md)。

## 即将到来的功能

- **__list缓存**：动态缓存缓存类的属性和方法，方便调试。
- **Class文件**: 从包含类定义的lua文件中导入类，就像导入模块一样简单。
- **私有成员**: 引入一个私有成员的储存机制，增强对象的封装性和隐私性。
- **命名空间**: 引入命名空间机制以应对类名冲突。

## 贡献

欢迎 Fork 本仓库并提交 Pull Request。如果发现任何 bug 或问题，请在仓库中提交 issue 告诉我。
