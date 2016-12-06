
# rufus-lua

[![Gem Version](https://badge.fury.io/rb/rufus-lua.svg)](http://badge.fury.io/rb/rufus-lua)

Lua embedded in Ruby, via Ruby FFI.

(Lua 5.1.x only, [no luajit](https://github.com/jmettraux/rufus-lua/issues/37) out of the box).


## Lua

http://www.lua.org/about.html says :


> Lua is a powerful, fast, lightweight, embeddable scripting language.
>
> Lua combines simple procedural syntax with powerful data description
> constructs based on associative arrays and extensible semantics. Lua is
> dynamically typed, runs by interpreting bytecode for a register-based
> virtual machine, and has automatic memory management with incremental
> garbage collection, making it ideal for configuration, scripting, and
> rapid prototyping.

http://www.lua.org/


## other Ruby and Lua bridges / connectors

* https://github.com/glejeune/ruby-lua by Gregoire Lejeune
* http://rubyluabridge.rubyforge.org/ by Evan Wies
* https://github.com/whitequark/rlua by Peter Zotov


## getting Lua on your system

On Debian GNU/Linux, I do

```
sudo apt-get install liblua5.1-0
```

If your system's package manager doesn't have some version (5.1.x) of Lua around, jump to [compiling liblua.dylib](#compiling-libluadylib-osx) below or look at the [LuaBinaries solution](#lua-binaries-gnulinux) for GNU/Linux.

Rufus-lua will look for library in a [list of know places](https://github.com/jmettraux/rufus-lua/blob/9ddf26cde9f4a73115032504ad7f7eb688849b73/lib/rufus/lua/lib.rb#L38-L50).

If it doesn't find the Lua dynamic library or if it picks the wrong one, it's OK to set the `LUA_LIB` environment variable. For example:

```bash
LUA_LIB=~/mystuff/lualib.5.1.4.so ruby myluacode.rb
```
or
```bash
export LUA_LIB=~/mystuff/lualib.5.1.4.so
# ...
ruby myluacode.rb
```

On Windows try using [rufus-lua-win](https://github.com/ukoloff/rufus-lua-win) gem.

## using rufus-lua

```
gem install rufus-lua
```

or add to your Gemfile:

```ruby
  gem 'rufus-lua'
```

then

```ruby
require 'rufus-lua'

s = Rufus::Lua::State.new

puts s.eval("return table.concat({ 'hello', 'from', 'Lua' }, ' ')")
  #
  # => "Hello from Lua"

s.close
```


### binding Ruby code as Lua functions

```ruby
require 'rufus-lua'

s = Rufus::Lua::State.new

s.function 'key_up' do |table|
  table.inject({}) do |h, (k, v)|
    h[k.to_s.upcase] = v
  end
end

p s.eval(%{
  local table = { CoW = 2, pigs = 3, DUCKS = 'none' }
  return key_up(table) -- calling Ruby from Lua...
}).to_h
  # => { 'COW' => 2.0, 'DUCKS => 'none', 'PIGS' => 3.0 }

s.close
```


It's OK to bind a function inside of a table (library):

```ruby
require 'rufus-lua'

s = Rufus::Lua::State.new

s.eval("rubies = {}")
s.function 'add' do |x, y|
  x + y
end

s.eval("rubies.add(1, 2)")
  # => 3.0

s.close
```


You can omit the table definition (only 1 level allowed here though):

```ruby
require 'rufus-lua'

s = Rufus::Lua::State.new

s.function 'rubies.add' do |x, y|
  x + y
end

s.eval("rubies.add(1, 2)")
  # => 3.0

s.close
```


The specs contain more examples:

https://github.com/jmettraux/rufus-lua/tree/master/spec/


### eval(code[, binding[, filename[, lineno ]]])

The examples so far have shown `Rufus::Lua::State#eval` being used with a single argument, a piece of code.

But this rufus-lua eval mimics the Ruby `eval` and lets one specify binding, filename and lineno.

(TODO) Binding hasn't yet been implemented. It'll probaby be with `setfenv` but nothing sure yet. Stick a `nil` to it for now.

The string of Lua code may come from wild places, it may help to flag it with arbitrary filename and lineno.

```ruby
require 'rufus-lua'

lua = Rufus::Lua::State.new

lua.eval('print("hello")', nil, 'myluastuff/hello.lua', 77)
```

### set_error_handler

`set_error_handler` gives a little bit of control on how error messages are prepared when errors occur in the Lua interpreter.

Here are set of examples for each of the possible error handler kind: Lua code, Ruby block, `:traceback`.

```ruby
require 'rufus-lua'

lua = Rufus::Lua::State.new

#
# no error handler

begin
  lua.eval('error("ouch!")')
rescue => e
  puts(e)
end
  # --> eval:pcall : '[string "line"]:1: ouch!' (2 LUA_ERRRUN)

#
# Lua error handler

lua.set_error_handler(%{
  function (msg)
    return 'something went wrong: ' .. string.gmatch(msg, ": (.+)$")()
  end
})

begin
  lua.eval('error("ouch!")')
rescue => e
  puts(e)
end
  # --> eval:pcall : 'something went wrong: ouch!' (2 LUA_ERRRUN)

#
# Ruby block error handler

lua.set_error_handler do |msg|
  ([ msg.split.last ] * 3).join(' ')
end

begin
  lua.eval('error("ouch!")')
rescue => e
  puts(e)
end
  # --> eval:pcall : 'ouch! ouch! ouch!' (2 LUA_ERRRUN)

#
# prepackaged :traceback handler

lua.set_error_handler(:traceback)

begin
  lua.eval('error("ouch!")')
rescue => e
  puts(e)
end
  # -->
  #   eval:pcall : '[string "line"]:1: ouch!
  #   stack traceback:
  #   	[C]: in function 'error'
  #   	[string "line"]:1: in main chunk' (2 LUA_ERRRUN)

#
# unset the error handler

lua.set_error_handler(nil)

begin
  lua.eval('error("ouch!")')
rescue => e
  puts(e)
end
  # --> eval:pcall : '[string "line"]:1: ouch!' (2 LUA_ERRRUN)
  # (back to default)
```


## compiling liblua.dylib (OSX)

original instructions by Adrian Perez at:

http://lua-users.org/lists/lua-l/2006-09/msg00894.html

get the source at:

http://www.lua.org/ftp/lua-5.1.4.tar.gz

then

```
tar xzvf lua-5.1.4.tar.gz
cd lua-5.1.4
```

Modify the file `src/Makefile` as per http://lua-users.org/lists/lua-l/2006-09/msg00894.html

It's mostly about adding that rule to the `src/Makefile`:
```make
liblua.dylib: $(CORE_O) $(LIB_O)
	$(CC) -dynamiclib -o $@ $^ $(LIBS)
```

Here's how to build the library file and deploy it:
```
make
make macosx
make -C src liblua.dylib
sudo cp src/liblua.dylib /usr/local/lib/

sudo make macosx install
```

I tend to copy the lib with

```
sudo cp src/liblua.dylib /usr/local/lib/liblua.5.1.4.dylib

# instead of
#sudo cp src/liblua.dylib /usr/local/lib/
```

## lua binaries (GNU/Linux)

Hat tip to [Micka33](https://github.com/Micka33) for pointing to [LuaBinaries](http://luabinaries.sourceforge.net/download.html) in [issue #34](https://github.com/jmettraux/rufus-lua/issues/34)


## tested with

ruby 1.9.1p0, jruby 1.2.0
jruby 1.1.6 has an issue with errors raised inside of Ruby functions (callbacks)

ruby-ffi 0.4.0 and 0.5.0

I run the specs with

```
bundle install # first time only
bundle exec rspec
```


## dependencies

the ruby gem 'ffi'


## issue tracker

http://github.com/jmettraux/rufus-lua/issues


## source

http://github.com/jmettraux/rufus-lua

```
git clone git://github.com/jmettraux/rufus-lua.git
```


## authors and credits

see [CREDITS.txt](CREDITS.txt)


## license

MIT

Lua itself is licensed under the MIT license as well :

http://www.lua.org/license.html

