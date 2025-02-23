切换至 [中文](https://github.com/blanhhy/luaclass/blob/main/README.md)

# Luaclass

**Luaclass** is a Lua module designed to bring an object-oriented programming (OOP) approach to Lua by implementing class-based inheritance, method lookup, and other OOP features in a lightweight and intuitive way. This module allows you to create classes, inherit from base classes, and manage class properties and methods with a flexible, dynamic approach, all wrapped in a familiar syntax for developers who prefer object-oriented paradigms.

## Features

- **Class Creation**: Easily define classes using class() and manage inheritance hierarchies, or creat dynamically by calling the method itself.
- **Inheritance and Overriding**: Support for class inheritance, allowing classes to inherit methods and properties from base classes or override them.
- **Super Class Access**: Easily call superclass methods with the `super()` function.
- **Custom Initialization**: Support for custom initialization methods (by creating `__init` method) during object instantiation.
- **Compatibility with Lua Metamethods**: Fully compatible with native Lua metamethods, including __index, __call, and __tostring.
- **Cache-like `__list` Function**: List all properties and methods of a class, similar to Python's `__dict__`.

## Requirements

Please check the full list of required dependencies [here](https://github.com/blanhhy/luaclass/blob/main/requirement.md).

## Installation

You can install **Luaclass** by simply downloading the module main file ([luaclass.lua](https://github.com/blanhhy/luaclass/blob/main/luaclass.lua)) and import it into your project

If you are using Fusion App2 on Android, you can download the dedicated module version from the [github release](https://github.com/blanhhy/luaclass/releases) page.

To use the module in your Lua script, simply include it like this:

```lua
local luaclass = require("luaclass")
```

## Example

Here is a basic usage example:

```lua
-- Define a class "MyClass"
local my = class("MyClass")

function hello(self)
  print("Hello from " .. self.__classname)
end

class.end()

-- Create an instance of "MyClass"
local obj = my()

-- Call the method
obj:hello()
```

or you can use this if you like:

```lua
-- Define a class "MyClass"
local my = class("MyClass")

function my:hello()
  print("Hello from " .. self.__classname)
end

class.end()

-- Create an instance of "MyClass"
local obj = my()

-- Call the method
obj:hello()
```

### Inheritance Example

```lua
-- Define a base class
local Animal = class("Animal")
function speak(self)
  print(self.name .. " makes a sound.")
end
class.end()

-- Define a subclass
local Dog = class("Dog", Animal)
function __init(self, name)
  self.name = name
end
function speak(self)
  print(self.name .. " barks.")
end
class.end()

-- Create an instance of the Dog class
local dog = Dog("Buddy")
dog:speak()  -- Output: Buddy barks.

-- Call a method from the super class
super(dog):speak()  -- Output: Buddy makes a sound.
```

For further details and examples, please refer to the [demo](https://github.com/blanhhy/luaclass/blob/main/demo.lua).

## Changelog

### v1.4
- Unified syntax for calling superclass methods (`super(cls_or_obj):method()`)
- Improved class creation syntax: `local myclass = class("name")` or `local myclass = class("name", parent)`
- Fixed performance issues with `super()` function and improved caching.

### v1.3
- Optimized performance.
- Fixed minor bugs related to method lookup.

### v1.0
- Full rewrite with a new object-oriented class system.
- Added `super` function for calling superclass methods.
- Introduced elegantly class creation using `class()` syntax.

For a full list of changes, check the [changelog](https://github.com/blanhhy/luaclass/blob/main/changelog.md).

## Upcoming Features

- **Multiple Inheritance**: New inheritance chain mechanism to support multiple inheritance.
- **Lazy Instantiation**: Support for delayed instantiation of class instances.
- **Advanced Caching**: Cache properties in a list-like structure (similar to Python’s `__dict__`).

## Contribution

Feel free to fork this repository and submit pull requests. If you find any bugs or issues, open an issue in the repository.