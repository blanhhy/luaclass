### v1.6
**Changelog**:
* 全面支持多继承，可以通过 `A.__mro` 来查看继承链
* 改进了类的创建语法，新的语法有一点像 C++ ，先用一行 `class "A"` 或 `class.A` 声明一个类，再用一个表 `{ xxx = ooo; }` 描述类中的成员
（详见 [demo](https://github.com/blanhhy/luaclass/blob/main/demo.lua) ）
* 提供一个新的 `isinstance` 函数，作用和 Python 中的类似
* 删除了 `__list` 方法

**detail**: https://github.com/blanhhy/luaclass/commit/5b927a23b973ee7177913060e86cf547021de6c6

-------

**Full Changelog**:
https://github.com/blanhhy/luaclass/compare/v1.4...v1.6

>大更新
>1. 关于 compute_mro 函数
>
>　新增 MRO 机制以支持多继承，现在类的 __superclass 属性是一个包含所有直接超类的序列，而 MRO 会存储在 __mro 属性中
>
>　新增 compute_mro 函数用于计算 MRO 
>
>　由于 Python 的C3线性化算法在 Lua 中难以实现，即使硬要实现也会因为过多的遍历严重影响性能，因此最终采用了“分块线性化”算法，损耗较少的性能就能得到和C3大差不差的结果（由于C3是深度优先，所有有时还是会有一点差异）
>
>　分块线性化算法：广度优先，先来后到，维持单调性。发生单调性冲突时，会拒绝创建类并提供冲突的具体位置
>
>　现在 lookup 函数会按照 MRO 查找属性和方法
>
>2. 关于 class_creater 函数
>
>　再次更新了语法，新的语法有一点像 C++ ，现在创建类的语法类似 class "类名" {成员表} 或 class.类名 {成员表}
>
>　新增了 class_creater 函数，原来的 classstart 和 classend 被移除
>
>　统一了类的创建方式，即所有类创建都依靠 luaclass 的实例化，现在的 class_creater 只是对 luaclass 的 __init 方法的封装，导出的 class 对象只是 class_creater 的语法糖
>
>　现在 class_creater 会自动绑定同类名的环境变量名，创建语法更为简洁，但副作用就是可能导致变量名冲突，不过在大多数情况下没问题，即使发生了也可以手动创建一个局部引用（local myclass class "myclass" {}），然后删除全局引用（_ENV.myclass = nil）
>
>　新的创建流程直接获取类的原表，不再需要原来依赖debug库的切换环境操作，提高了性能
>
>　现在唯一的弊端就是表中不支持 function xx() 语法，必须用 xx = function() 来定义方法
>
>3. 关于 interceptor 对象
>
>　现在拦截器对象会缓存 super 调用产生的闭包，如果之后进行了同样的方法调用行为（指同一个对象或类调用同一个方法），则不会重复查找，也不会创建新的闭包
>
>　缓存空间采用弱引用键模式，因此对象或类被销毁时，它在 interceptor 对象中的缓存空间会自动清除
>
>4. 关于 isinstance 函数
>
>　isinstance 函数用于判断一个对象是不是某个类的实例，和 Python 中的类似， isinstance 函数会考虑继承关系。
>
>5. 其他小改动
>
>　暂时移除了现有的 __list 方法，以后会加入新的 __list 属性
>
>　新增依赖 unifuncex 中的 table.tostring 函数，用于抛出错误时打印 MRO 处理过程



### v1.4
**Changelog**:
* 统一了子类和超类方法的调用语法（类似于`super(cls_or_obj):method()` ）
* 优化了创建类的语法，现在开始创建类的语句类似于`local myclass = class "name"` 或`local myclass = class("name", parent)` ，结束语句统一为`class.end() `
（详见 [demo](https://github.com/blanhhy/luaclass/blob/main/demo.lua) ）
* 重写撰写了FA2模块介绍中`examplelist` 部分

-------

**Full Changelog**:https://github.com/blanhhy/luaclass/compare/v1.3...v1.4

>改进了语法
>1. 将super函数的调用语法调整至和普通的table（以及其他的类或者对象）一致，贴合lua原生的使用体验
>2. 调整了class函数的逻辑，将赋值、命名、绑定超类的操作全部放在创建类的开头，创建结束后只需写下class.end()，更加符合人类直觉



### v1.3
**Changelog**:

* 改进了性能

**detail**: https://github.com/blanhhy/luaclass/commit/de1265bd80cd4e09a259ea0163ae40fcd508aeec

-------

**Full Changelog**: https://github.com/blanhhy/luaclass/compare/v1.0...v1.3

>主要的改动包括：
>1. 现在对象的类会保存在对象内部的__class属性中，这样查找类或超类的属性和方法就无需访获取元表了
>2. 将super函数中的拦截器table独立出来，而后续使用则依靠super函数向拦截器中添加参数，从而不再需要每次创建新的拦截器
>3. 把一些反复使用的字符串加到了局部变量当中以提升访问性能



### v1.0
**Changelog**:
* 采用全新的实现方式，彻底重写了整个模块
* 兼容Lua原生的元方法
* 使用新的`unifuncex` 与`luaset` 模块（见 [requirement](https://github.com/blanhhy/luaclass/blob/main/requirement.md) ）
* 现在`super` 函数既可以指定对象或类调用，也可以在类的方法中直接调用（详见 [demo](https://github.com/blanhhy/luaclass/blob/main/demo.lua) ）
* 更加优雅的类创建语法，只需用两个`class()` 替代创建普通表（table）时的`{ }` 即可（详见 [demo](https://github.com/blanhhy/luaclass/blob/main/demo.lua) ）
* 现在可以直接调用本模块来动态创建一个类（详见 [demo](https://github.com/blanhhy/luaclass/blob/main/demo.lua) ）
* 移除了`print` 方法，取而代之的是`__list` 方法，返回一个集合（concrete set）