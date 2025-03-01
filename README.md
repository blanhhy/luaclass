Change to [Engnish](https://github.com/blanhhy/luaclass/blob/main/README_en.md)

# Luaclass

**Luaclass** 是一个为 Lua 提供面向对象编程（OOP）支持的模块，旨在通过实现类继承、方法查找等 OOP 特性，轻量而直观地引入面向对象的编程范式。该模块允许创建类、继承基类，并灵活地管理类的属性和方法，所有功能都以一种开发者熟悉的语法进行封装。

## 特性

- **类创建**：通过 `class()` 方法轻松定义类，并管理继承关系，也可以通过动态调用来创建类。
- **继承与覆盖**：支持类继承，允许类从基类继承方法和属性，或重写它们。
- **超类访问**：通过 `super()` 函数轻松调用超类方法。
- **自定义初始化**：支持在实例化时通过创建 `__init` 方法进行自定义初始化。
- **兼容 Lua 元方法**：完全兼容 Lua 原生的元方法，如 `__index`、`__call`、`__tostring` 等。
- **类似缓存的 `__list` 功能**：列出类的所有属性和方法，类似于 Python 中的 `__dict__`。

## 依赖项

本模块依赖于我的另外两个模块。

具体依赖的函数请点击 [这里](https://github.com/blanhhy/luaclass/blob/main/requirement.md) 来查看。

## 安装

只需要下载模块的主文件（[luaclass.lua](https://github.com/blanhhy/luaclass/blob/main/luaclass.lua)）并将其导入到 Lua 项目中来安装 **Luaclass**。

如果你使用 Android 上的 Fusion App2 的话，可以从 [Github 发布页](https://github.com/blanhhy/luaclass/releases) 下载专用版本。

在 Lua 脚本中使用该模块，只需像这样导入：

```lua
local luaclass = require("luaclass")
```

## 示例

以下是一个基础的使用示例：

```lua
-- 定义一个类 "MyClass"
local my = class("MyClass")

function hello(self)
  print("Hello from " .. self.__classname)
end

class.end()

-- 创建 "MyClass" 的实例
local obj = my()

-- 调用方法
obj:hello()
```

或者如果你喜欢的话，也可以这么写：

```lua
-- 定义一个类 "MyClass"
local my = class("MyClass")

function my:hello()
  print("Hello from " .. self.__classname)
end

class.end()

-- 创建 "MyClass" 的实例
local obj = my()

-- 调用方法
obj:hello()
```

### 继承示例

```lua
-- 定义一个基类
local Animal = class("Animal")
function speak(self)
  print(self.name .. " makes a sound.")
end
class.end()

-- 定义一个子类
local Dog = class("Dog", Animal)
function __init(self, name)
  self.name = name
end
function speak(self)
  print(self.name .. " barks.")
end
class.end()

-- 创建 Dog 类的实例
local dog = Dog("Buddy")
dog:speak()  -- 输出: Buddy barks.

-- 调用超类的方法
super(dog):speak()  -- 输出: Buddy makes a sound.
```

更多示例请参见 [demo](https://github.com/blanhhy/luaclass/blob/main/demo.lua)。

## 更新日志

### v1.4
- 统一了超类方法调用语法 (`super(cls_or_obj):method()`)
- 改进了类创建语法：`local myclass = class("name")` 或 `local myclass = class("name", parent)`
- 修复了 `super()` 函数的性能问题并改善了缓存机制。

### v1.3
- 优化了性能。
- 修复了与方法查找相关的若干小问题。

### v1.0
- 全面重写了模块，采用了新的面向对象类系统。
- 增加了 `super` 函数用于调用超类方法。
- 引入了更优雅的类创建语法 `class()`。

详细更新请查阅 [更新日志](https://github.com/blanhhy/luaclass/blob/main/changelog.md)。

## 即将到来的功能

- **多重继承**：新的继承链机制以支持多重继承。
- **延迟实例化**：支持延迟实例化类实例。
- **高级缓存**：像 Python 的 `__dict__` 一样缓存类的属性。
- **class 文件**：支持从lua文件中导入class。

## 贡献

欢迎 Fork 本仓库并提交 Pull Request。如果你在使用时发现任何 bug 或问题，请在仓库中提交 issue 告诉我。