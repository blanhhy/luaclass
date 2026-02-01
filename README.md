# Luaclass

这是一个为 Lua 提供基于类的面向对象编程（Class-based OOP）支持的模块，旨在让 Lua 面向对象编程变得更加简单、优雅，同时功能强大。

## 安装 & 导入

下载模块的主文件夹（[luaclass](https://github.com/blanhhy/luaclass/blob/main/luaclass)）复制到你的 Lua 模块路径。

在 Lua 脚本中使用该模块：

```lua
require "luaclass"
```

模块包含以下接口：

- `luaclass`: 元类，相当于 Python `type`
- `Object`: 所有类的基类
- `class`: 定义类的关键词
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

详细介绍文档请移步 [doc.md](https://github.com/blanhhy/luaclass/blob/main/doc.md)

更多示例代码请参见 [demo](https://github.com/blanhhy/luaclass/blob/main/demo)

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
