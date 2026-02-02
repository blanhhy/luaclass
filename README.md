# Luaclass

Luaclass 是一个纯 Lua 实现的面向对象编程（OOP）库，旨在为 Lua 提供完整的面向对象编程能力，支持 Lua 5.1+ 版本（包括 LuaJIT）

## 安装 & 导入

下载模块的主文件夹（[luaclass](https://github.com/blanhhy/luaclass/blob/main/luaclass)）复制到你的 Lua 模块路径。

在 Lua 脚本中使用该模块：

```lua
require "luaclass"
```

模块包含以下接口：

- `luaclass`: 元类，相当于 Python `type`
- `Object`: 所有类的基类
- `class`: 定义类的关键字
- `super`: 调用已经被重写的基类方法
- `decl`: 用于声明字段和抽象方法
- `isinstance`: 判断对象是否为某个类实例
- `namespace`: 提供命名空间支持的库

正常情况下这些是自动注入到 `_G` 的

## 使用 & 文档

下面是一套简单的完整使用流程：

```lua
require "luaclass" -- 导入库

-- 定义一个全局类 MyClass
class "MyClass" {
  greet = function(self)
    print("Hello from "..tostring(luaclass(self)));
  end;
}

-- 创建 MyClass 的实例
local obj = MyClass()

-- 调用实例方法
obj:greet() --> Hello from MyClass
```

上面的例子中出现了：

- 类的定义
语法为 `class "<name>" {<body>}`，定义体是一个 Lua 表

- 实例方法 
特点在于第一个参数是实例本身，Lua 中习惯用 `self` 命名

- luaclass 
和 Python 的 `type` 几乎是一致的，可以用它获取对象的类型

- 实例化
有 Python 风格 `clazz()`，也有 Lua 风格 `clazz:new()`

除了这些之外，Luaclass 还有许多内容，详细的介绍见 [使用文档](https://github.com/blanhhy/luaclass/blob/main/doc.md)，如果你想要可运行的代码示例，可以前往 [demo](https://github.com/blanhhy/luaclass/blob/main/demo) 获取

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

1. `core`：负责对象和类的创建
2. `inherit` 负责实现继承 & 多态
3. `share`：模块级共享模块
4. `util`：提供给用户的可选工具类
5. `main.lua`：主入口文件，整理了所有模块的接口
6. `init.lua`：初始化文件，将模块接口导入到全局环境

## 反馈

如果你在测试/使用的过程中发现任何问题，请提交 issue 告知我
