# Rtype: ruby with type
[![Gem Version](https://badge.fury.io/rb/rtype.svg)](https://badge.fury.io/rb/rtype)
[![Build Status](https://travis-ci.org/sputnikgugja/rtype.svg?branch=master)](https://travis-ci.org/sputnikgugja/rtype)
[![Coverage Status](https://coveralls.io/repos/github/sputnikgugja/rtype/badge.svg?branch=master)](https://coveralls.io/github/sputnikgugja/rtype?branch=master)

You can do the type checking in Ruby with this gem!

```ruby
require 'rtype'

class Test
  rtype [:to_i, Numeric] => Numeric
  def sum(a, b)
    a.to_i + b
  end

  rtype {state: Boolean} => Boolean
  def self.invert(state:)
    !state
  end
end

Test.new.sum(123, "asd")
# (Rtype::ArgumentTypeError) for 2nd argument:
# Expected "asd" to be a Numeric

Test::invert(state: 0)
# (Rtype::ArgumentTypeError) for 'state' argument:
# Expected 0 to be a Boolean
```

## Requirements
- Ruby >= 2.1
- MRI
  - If C native extension is used, otherwise it is not required
- JRuby
  - If Java extension is used, otherwise it is not required

## Features
- Provide type checking for arguments and return
- Support type checking for [keyword argument](#keyword-argument)
- [Type checking for array elements](#array)
- [Type checking for hash elements](#hash)
- [Duck typing](#duck-typing)
- Custom type behavior

## Installation
Run `gem install rtype` or add `gem 'rtype'` to your `Gemfile`

And add to your `.rb` source file:
```ruby
require 'rtype'
```

### Native extension
Rtype itself is pure-ruby gem. but you can make it more faster by using native extension.

#### Native extension for MRI
Just run
```ruby
gem install rtype-native
```
or add to your `Gemfile`:
```ruby
gem 'rtype-native'
```
then, Rtype use it. (Do not `require 'rtype-native'`)

#### Java extension for JRuby
Just run
```ruby
gem install rtype-java
```
or add to your `Gemfile`:
```ruby
gem 'rtype-java'
```
then, Rtype use it. (Do not `require 'rtype-java'`)

## Usage

### Supported Type Behaviors
- `Module`
  - Value must be an instance of this module/class or one of its superclasses
  - `Any` : An alias for `BasicObject` (means Any Object)
  - `Boolean` : `true` or `false`
- `Symbol`
  - Value must have(respond to) a method with this name
- `Regexp`
  - Value must match this regexp pattern
- `Range`
  - Value must be included in this range
- `Array` (tuple)
  - Value must be an array
  - Each of value's elements must be valid
  - Value's length must be equal to the array's length
  - Of course, nested array works
  - Example: [Array](#array)
  - This can be used as a tuple
- `Hash`
  - Value must be an hash
  - Each of value’s elements must be valid
  - Value's key list must be equal to the hash's key list
  - **String** key is **different** from **symbol** key
  - vs Keyword arguments
    - `[{}]` is **not** hash type argument. it is keyword argument because its position is last
    - `[{}, {}]` is empty hash type argument (first) and one empty keyword argument (second)
    - `[{}, {}, {}]` is two empty hash type argument (first, second) and empty keyword argument (last)
    - `{}` is keyword argument. non-keyword arguments must be in array.
  - Of course, nested hash works
  - Example: [Hash](#hash)
- `Proc`
  - Value must return a truthy value for this proc
- `true`
  - Value must be **truthy**
- `false`
  - Value must be **falsy**
- `nil`
  - Only available for **return type**. void return type in other languages
- Special Behaviors
  - `Rtype::and(*types)` : Ensure value is valid for all the types
    - `Rtype::and(*types)`
    - `Rtype::Behavior::And[*types]`
    - `include Rtype::Behavior; And[...]`
    - `obj.and(*others)` (core extension)

  - `Rtype::or(*types)` : Ensure value is valid for at least one of the types
    - `Rtype::or(*types)`
    - `Rtype::Behavior::Or[*types]`
    - `include Rtype::Behavior; Or[...]`
    - `obj.or(*others)` (core extension)

  - `Rtype::xor(*types)` : Ensure value is valid for only one of the types
    - `Rtype::xor(*types)`
    - `Rtype::Behavior::Xor[*types]`
    - `include Rtype::Behavior; Xor[...]`
    - `obj.xor(*others)` (core extension)

  - `Rtype::not(*types)` : Ensure value is not valid for all the types
    - `Rtype::not(*types)`
    - `Rtype::Behavior::Not[*types]`
    - `include Rtype::Behavior; Not[...]`
    - `obj.not` (core extension)

  - `Rtype::nilable(type)` : Ensure value can be nil
    - `Rtype::nilable(type)`
    - `Rtype::Behavior::Nilable[type]`
    - `include Rtype::Behavior; Nilable[...]`
    - `obj.nilable` (core extension)
    - `obj.or_nil` (core extension)

  - You can create custom behavior by extending `Rtype::Behavior::Base`

### Examples

#### Basic
```ruby
require 'rtype'

class Example
  rtype [Integer] => nil
  def test(i)
  end
  
  rtype [Any] => nil
  def any_type_arg(arg)
  end
  
  rtype [] => Integer
  def return_type_test
    "not integer"
  end
end

e = Example.new
e.test("not integer")
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected "not integer" to be a Integer

e.any_type_arg("Any argument!") # Works

e.return_type_test
# (Rtype::ReturnTypeError) for return:
# Expected "not integer" to be a Integer
```

#### Keyword argument
```ruby
require 'rtype'

class Example
  rtype {name: String} => Any
  def say_your_name(name:)
    puts "My name is #{name}"
  end
  
  # Mixing positional arguments and keyword arguments
  rtype [String, {age: Integer}] => Any
  def name_and_age(name, age:)
    puts "Name: #{name}, Age: #{age}"
  end
end

Example.new.say_your_name(name: "Babo") # My name is Babo
Example.new.name_and_age("Bamboo", age: 100) # Name: Bamboo, Age: 100

Example.new.say_your_name(name: 12345)
# (Rtype::ArgumentTypeError) for 'name' argument:
# Expected 12345 to be a String
```

#### Duck typing
```ruby
require 'rtype'

class Duck
  rtype [:to_i] => Any
  def says(i)
    puts "duck:" + " quack"*i.to_i
  end
end

Duck.new.says("2") # duck: quack quack
```

#### Array
This can be used as a tuple.

```ruby
rtype :func, [[Numeric, Numeric]] => Any
def func(arr)
  puts "Your location is (#{arr[0]}, #{arr[1]}). I will look for you. I will find you"
end

func [1, "str"]
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected [1, "str"] to be an array with 2 elements:
# - [0] index : Expected 1 to be a Numeric
# - [1] index : Expected "str" to be a Numeric

func [1, 2, 3]
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected [1, 2, 3] to be an array with 2 elements:
# - [0] index : Expected 1 to be a Numeric
# - [1] index : Expected 2 to be a Numeric

func [1]
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected [1] to be an array with 2 elements:
# - [0] index : Expected 1 to be a Numeric
# - [1] index : Expected nil to be a Numeric

func [1, 2] # Your location is (1, 2). I will look for you. I will find you
```

#### Hash
```ruby
# last hash element is keyword arguments
rtype :func, [{msg: String}, {}] => Any
def func(hash)
  puts hash[:msg]
end

# last hash is keyword arguments
func({}, {})
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected {} to be an hash with 1 elements:
# - msg : Expected nil to be a String

func({msg: 123}, {})
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected {:msg=>123} to be an hash with 1 elements:
# - msg : Expected 123 to be a String

func({msg: "hello", key: 'value'}, {})
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected {:msg=>"hello", :key=>"value"} to be an hash with 1 elements:
# - msg : Expected "hello" to be a String

func({"msg" => "hello hash"}, {})
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected {"msg"=>"hello hash"} to be an hash with 1 elements:
# - msg : Expected nil to be a String

func({msg: "hello hash"}, {}) # hello hash
```

#### rtype with attr_accessor
`rtype_accessor` : calls attr_accessor and makes it typed method

You can use `rtype_accessor_self` for static accessor.

```ruby
require 'rtype'

class Example
  rtype_accessor :value, String

  def initialize
    @value = 456
  end
end

Example.new.value = 123
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected 123 to be a String

Example.new.value
# (Rtype::ReturnTypeError) for return:
# Expected 456 to be a String
```

#### Combined type
```ruby
### TEST 1 ###
require 'rtype'

class Example
  rtype [String.and(:func)] => Any
  # also works:
  # rtype [Rtype::and(String, :func)] => Any
  def and_test(arg)
  end
end

Example.new.and_test("A string")
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected "A string" to be a String
# AND Expected "A string" to respond to :func
```
```ruby
### TEST 2 ###
# ... require rtype and define Example the same as above ...

class String
  def func; end
end

Example.new.and_test("A string") # Works!
```

#### Combined duck type
Application of duck typing and combined type

```ruby
require 'rtype'

module Game
  ENEMY = [
    :name,
    :level
  ]
  
  class Player < Entity
    include Rtype::Behavior

    rtype [And[*ENEMY]] => Any
    def attacks(enemy)
      "Player attacks '#{enemy.name}' (level #{enemy.level})!"
    end
  end
  
  class Slime < Entity
    def name
      "Powerful Slime"
    end
    
    def level
      123
    end
  end
end

Game::Player.new.attacks Game::Slime.new
# Player attacks 'Powerful Slime' (level 123)!
```

#### Position of `rtype` && (Specify method name || annotation mode) && (Symbol || String)
```ruby
require 'rtype'

class Example
  # Recommended. Annotation mode (no method name required)
  rtype [Integer, String] => String
  def hello_world(i, str)
    puts "Hello? #{i} #{st
  end

  # Works (specifying method name)
  rtype :hello_world, [Integer, String] => String
  def hello_world(i, str)
    puts "Hello? #{i} #{st
  end
  
  # Works
  def hello_world_two(i, str)
    puts "Hello? #{i} #{str}"
  end
  rtype :hello_world_two, [Integer, String] => String
  
  # Also works (String will be converted to Symbol)
  rtype 'hello_world_three', [Integer, String] => String
  def hello_world_three(i, str)
    puts "Hello? #{i} #{str}"
  end

  # Don't works. `rtype` works for next method
  def hello_world_four(i, str)
    puts "Hello? #{i} #{str}"
  end
  rtype [Integer, String] => String
end
```

#### Outside of module (root)
Outside of module, annotation mode don't works. You must specify method name.

```ruby
rtype :say, [String] => Any
def say(message)
  puts message
end

Test.new.say "Hello" # Hello

rtype [String] => Any
# (ArgumentError) Annotation mode not working out of module
```

#### Static(singleton) method
rtype annotation mode works both instance and class method

```ruby
require 'rtype'

class Example
  rtype [:to_i] => Any
  def self.say_ya(i)
    puts "say" + " ya"*i.to_i
  end
end

Example::say_ya(3) #say ya ya ya
```

however, if you specify method name, you must use `rtype_self` instead of `rtype`

```ruby
require 'rtype'

class Example
  rtype_self :say_ya, [:to_i] => Any
  def self.say_ya(i)
    puts "say" + " ya"*i.to_i
  end
end

Example::say_ya(3) #say ya ya ya
```

#### Check type information
This is just the 'information'

Any change of this doesn't affect type checking

```ruby
require 'rtype'

class Example
  rtype [:to_i] => Any
  def test(i)
  end
end

Example.new.method(:test).type_info
# => [:to_i] => Any
Example.new.method(:test).argument_type
# => [:to_i]
Example.new.method(:test).return_type
# => Any
```

## Documentation
[RubyDoc.info](http://www.rubydoc.info/gems/rtype)

## Benchmarks
Result of `rake benchmark` ([source](https://github.com/sputnikgugja/rtype/tree/master/benchmark/benchmark.rb))

### MRI
```
Rtype with C native extension
Ruby version: 2.1.7
Ruby engine: ruby
Ruby description: ruby 2.1.7p400 (2015-08-18 revision 51632) [x64-mingw32]
Rtype version: 0.3.0
Rubype version: 0.3.1
Sig version: 1.0.1
Contracts version: 0.13.0
Typecheck version: 0.1.2
Warming up --------------------------------------
                pure    85.328k i/100ms
               rtype    25.665k i/100ms
              rubype    21.414k i/100ms
                 sig     8.921k i/100ms
           contracts     4.638k i/100ms
           typecheck     1.110k i/100ms
Calculating -------------------------------------
                pure      3.282M (± 2.7%) i/s -     16.468M
               rtype    339.065k (± 2.6%) i/s -      1.720M
              rubype    266.893k (± 5.9%) i/s -      1.349M
                 sig     99.952k (± 2.1%) i/s -    499.576k
           contracts     49.693k (± 1.5%) i/s -    250.452k
           typecheck     11.356k (± 1.6%) i/s -     57.720k

Comparison:
                pure:  3282431.9 i/s
               rtype:   339064.9 i/s - 9.68x slower
              rubype:   266892.9 i/s - 12.30x slower
                 sig:    99952.2 i/s - 32.84x slower
           contracts:    49693.0 i/s - 66.05x slower
           typecheck:    11355.9 i/s - 289.05x slower
```

### JRuby
Without Rubype that doesn't support JRuby

```
Rtype with Java extension
Ruby version: 2.2.3
Ruby engine: jruby
Ruby description: jruby 9.0.5.0 (2.2.3) 2016-01-26 7bee00d Java HotSpot(TM) 64-Bit Server VM 25.60-b23 on 1.8.0_60-b27 +jit [Windows 10-amd64]
Rtype version: 0.3.0
Sig version: 1.0.1
Contracts version: 0.13.0
Typecheck version: 0.1.2
Warming up --------------------------------------
                pure     9.994k i/100ms
               rtype     6.181k i/100ms
                 sig     4.041k i/100ms
           contracts   951.000  i/100ms
           typecheck   970.000  i/100ms
Calculating -------------------------------------
                pure      7.128M (?±35.6%) i/s -     30.831M
               rtype    121.556k (?± 6.2%) i/s -    605.738k
                 sig     72.187k (?± 6.4%) i/s -    359.649k
           contracts     24.984k (?± 3.9%) i/s -    125.532k
           typecheck     12.041k (?± 9.5%) i/s -     60.140k

Comparison:
                pure:  7128373.0 i/s
               rtype:   121555.8 i/s - 58.64x slower
                 sig:    72186.8 i/s - 98.75x slower
           contracts:    24984.5 i/s - 285.31x slower
           typecheck:    12041.0 i/s - 592.01x slower
```

## Rubype, Sig
Rtype is influenced by [Rubype](https://github.com/gogotanaka/Rubype) and [Sig](https://github.com/janlelis/sig).

If you don't like Rtype, You can use other type checking gem such as Contracts, Rubype, Rtc, Typecheck, Sig.

## Author
Sputnik Gugja (sputnikgugja@gmail.com)

## License
MIT license (@ Sputnik Gugja)

See `LICENSE` file.