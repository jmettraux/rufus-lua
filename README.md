
# rufus-lua

Lua embedded in Ruby, via Ruby FFI.

(Lua 5.1.x only, sorry).


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

If your system's package manager doesn't have some version (5.1.x) of Lua around, jump to [compiling liblua.dylib](#compiling-libluadylib) below.

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
require 'rufus/lua'

s = Rufus::Lua::State.new

puts s.eval("return table.concat({ 'hello', 'from', 'Lua' }, ' ')")
  #
  # => "Hello from Lua"

s.close
```


### binding Ruby code as Lua functions

```ruby
require 'rufus/lua'

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
require 'rufus/lua'

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
require 'rufus/lua'

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


## compiling liblua.dylib

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
make macosx # or make linux ...
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


## tested with

ruby 1.8.7p72, ruby 1.9.1p0, jruby 1.2.0
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

