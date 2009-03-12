
= rufus-lua

Lua embedded in Ruby, via ruby FFI

== Lua

from 

  http://www.lua.org/
  http://www.lua.org/about.html

"""
Lua is a powerful, fast, lightweight, embeddable scripting language.

Lua combines simple procedural syntax with powerful data description constructs based on associative arrays and extensible semantics. Lua is dynamically typed, runs by interpreting bytecode for a register-based virtual machine, and has automatic memory management with incremental garbage collection, making it ideal for configuration, scripting, and rapid prototyping. 
"""


== other Ruby and Lua bridges / connectors


  http://rubyluabridge.rubyforge.org/
  http://raa.ruby-lang.org/project/ruby-lua


== using rufus-lua

If you don't have liblua.dylib on your system, scroll until "compiling liblua.dylib" to learn how to get it.

  sudo gem install rufus-lua

then

  require 'rubygems'
  require 'rufus/lua'

  s = Rufus::Lua::State.new

  puts s.eval("return table.concat({ 'hello', 'from', 'Lua' }, ' ')")
    #
    # => "Hello from Lua"

  s.close


== compiling liblua.dylib

original instructions by Adrian Perez at :

  http://lua-users.org/lists/lua-l/2006-09/msg00894.html

get the source at 

  http://www.lua.org/ftp/lua-5.1.4.tar.gz

then

  tar xzvf lua-5.1.4.tar.gz
  cd lua-5.1.4

modify the file src/Makefile as per http://lua-users.org/lists/lua-l/2006-09/msg00894.html

  make 
  make masocx # or make linux ...
  make -C src src liblua.dylib

  sudo cp src/liblua.dylib /usr/local/lib/


== dependencies

the ruby gem 'ffi'


== mailing list

On the rufus-ruby list :

  http://groups.google.com/group/rufus-ruby


== issue tracker

  http://rubyforge.org/tracker/?atid=18584&group_id=4812&func=browse


== irc

irc.freenode.net #ruote


== source

http://github.com/jmettraux/rufus-lua

  git clone git://github.com/jmettraux/rufus-lua.git


== credits

many thanks to the authors of Ruby FFI, and of Lua

  http://kenai.com/projects/ruby-ffi/
  http://lua.org/


== authors

John Mettraux, jmettraux@gmail.com, http://jmettraux.wordpress.com


== the rest of Rufus

http://rufus.rubyforge.org


== license

MIT

Lua itself is licensed under the MIT license as well :

  http://www.lua.org/license.html

