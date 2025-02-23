v1.4
**Changelog**:
* 统一了子类和超类方法的调用语法（类似于`super(cls_or_obj):method()` ）
* 优化了创建类的语法，现在开始创建类的语句类似于`local myclass = class "name"` 或`local myclass = class("name", parent)` ，结束语句统一为`class.end() `
（详见 [demo](https://github.com/blanhhy/luaclass/blob/main/demo.lua) ）
* 重写撰写了FA2模块介绍中`examplelist` 部分

-------

**Full Changelog**:https://github.com/blanhhy/luaclass/compare/v1.3...v1.4

>改进了语法
1. 将super函数的调用语法调整至和普通的table（以及其他的类或者对象）一致，贴合lua原生的使用体验
2. 调整了class函数的逻辑，将赋值、命名、绑定超类的操作全部放在创建类的开头，创建结束后只需写下class.end()，更加符合人类直觉


v1.3
**Changelog**:

* 改进了性能

**detail**: https://github.com/blanhhy/luaclass/commit/de1265bd80cd4e09a259ea0163ae40fcd508aeec

-------

**Full Changelog**: https://github.com/blanhhy/luaclass/compare/v1.0...v1.3

>主要的改动包括：
1. 现在对象的类会保存在对象内部的__class属性中，这样查找类或超类的属性和方法就无需访获取元表了
2. 将super函数中的拦截器table独立出来，而后续使用则依靠super函数向拦截器中添加参数，从而不再需要每次创建新的拦截器
3. 把一些反复使用的字符串加到了局部变量当中以提升访问性能


v1.0
**Changelog**:
* 采用全新的实现方式，彻底重写了整个模块
* 兼容Lua原生的元方法
* 使用新的`unifuncex` 与`luaset` 模块（见 [requirement](https://github.com/blanhhy/luaclass/blob/main/requirement.md) ）
* 现在`super` 函数既可以指定对象或类调用，也可以在类的方法中直接调用（详见 [demo](https://github.com/blanhhy/luaclass/blob/main/demo.lua) ）
* 更加优雅的类创建语法，只需用两个`class()` 替代创建普通表（table）时的`{ }` 即可（详见 [demo](https://github.com/blanhhy/luaclass/blob/main/demo.lua) ）
* 现在可以直接调用本模块来动态创建一个类（详见 [demo](https://github.com/blanhhy/luaclass/blob/main/demo.lua) ）
* 移除了`print` 方法，取而代之的是`__list` 方法，返回一个集合（concrete set）