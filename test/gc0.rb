#
# Test garbage collection API from rufus-lua
#

$:.unshift('lib')

require 'rubygems'
require 'rufus/lua'


puts "Creating a new state..."
s = Rufus::Lua::State.new
puts "  #{s.gc_count} KB in use by Lua interpreter"
puts "  Calling into Lua..."
puts s.eval("return table.concat({ '    hello', 'from', 'Lua' }, ' ')")
puts "  #{s.gc_count} KB in use by Lua interpreter"
puts "Performing forced garbage collection..."
s.gc_collect!
puts "  #{s.gc_count} KB in use by Lua interpreter"
