Ordinary
========

Normalizer for any model

Installation
------------

Add this line to your application's Gemfile:

    gem 'ordinary'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ordinary

Usage
-----

First, you will include `Ordinary` to the model of the object. Following is an example of using ActiveModel.

```ruby
require 'ordinary'

class Person
  include ActiveModel::Model
  include Ordinary

  attr_accessor :name

  normalizes :name do |value|
    value.strip.squeeze(' ')
  end
end
```

You can get the normalized value with `#normalize_attribute` or `#normalized_ATTR_NAME`.

```ruby
person = Person.new(:name => '      Koyomi    Araragi   ')
puts person.name # => "      Koyomi    Araragi   "
puts person.normalize_attribute(:name) # => "Koyomi Araragi"
puts person.normalized_name # => "Koyomi Araragi"
```

And you can get the normalized model with `#normalize`.

```ruby
normalized_person = person.normalize
puts normalized_person.normalized? # => true
puts normalized_person.name # => "Koyomi Araragi"
```

Off course, it doesn't affect the original model.

```ruby
puts person.normalized? # => false
puts person.name # => "      Koyomi    Araragi   "
```

However, if you use `#normalize!`, the original model will also be normalized.

How to define normalization
---------------------------

How to define normalization is from where you include `Ordinary`.

```ruby
require 'ordinary'

class AnyModel
  include Ordinary

  # define normalization...
end
```

Incidentally, in order to enable to read and write to a target attirbute, you must define `#ATTR_NAME` and `#ATTR_NAME=`.

Normalization defines with `.normalizes`.

```ruby
class AnyModel
  # ...

  attr_accessor :attr1, :attr2

  normalizes :attr1, :attr2 do |value|
    # process for normalization
  end

  # ...
end
```

You can define in a variety of ways.

```ruby
class AnyModel
  # ...

  attr_accessor :attr1, :attr2

  # specify process with a block
  normalizes :attr1 do |value|
    "#{value}_1"
  end

  # if define normalization to same attribute, normalization runs in the order
  # in which you defined
  normalizes :attr1 do |value|
    "#{value}_2"
  end

  # If specify Proc to last argument, define composed unit in the Proc as
  # process of normalization (units described later)
  normalizes :attr2, lambda { lstrip | rstrip }

  # also specify both block and Proc (position of process of block decides by
  # block unit)
  normalizes :attr2, lambda { block | squeeze(' ') } do |value|
    "#{value}_3"
  end

  # also specify options
  normalizes :attr2, if: lambda { !attr2.nil? }, with: lambda { block | at(0) } do |value|
    (value.empty? or %w(0 false f).include?(value)) ? 'false' : 'true'
  end

  # ...
end
```

How to create an units module
-----------------------------

You can create a module bundled some units. You'll use `Ordinary::Module` to do so.

```ruby
require 'ordinary/module'

module AnyModule
  extend Ordinary::Module

  # define the module...
end
```

And you can register to use the module with `Ordinary.register`.

```ruby
require 'ordinary'

Ordinary.register(AnyModule)
```

### Define an unit

An unit can define with `.unit` in the module.

```ruby
module AnyModule
  # ...

  unit :some_unit do |value|
    # process for the unit...
  end

  # ...
end
```

You can define in a variety of ways.

```ruby
module AnyModule
  # ...

  # specify process with a block
  unit :lstrip do |value|
    value.lstrip
  end

  # okay as the argument
  unit :rstrip, lambda { |value| value.rstrip }

  # actually, above examples are okay at follows
  unit :lstrip

  # as aliasing
  unit :ltrim, :lstrip

  # by the way, units are defined as module functions, you can also see
  p lstrip # => #<Ordinary::Unit:0x0x007ff6ec8e7610 AnyModule#lstrip>

  # and compose units by #| (or #>>, #<<)
  unit :strip, lstrip | rstrip

  # ...
end
```

### Define a dependency

If exist dependencies to some libraries to units in the module, will resolve with `.requires`.

```ruby
module AnyModule
  # ...

  requires 'nkf'

  unit :to_half do |value|
    NKF.nkf('-wWZ1', value)
  end

  # ...
end
```

Contributing
------------

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
