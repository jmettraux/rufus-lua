
#
# sandbox experiment file with rufus-lua
#
# Thu Mar 12 15:54:30 JST 2009
#

$:.unshift('lib')

require 'rubygems'
require 'rufus/lua'


s = Rufus::Lua::State.new

puts s.eval("return table.concat({ 'hello', 'from', 'Lua' }, ' ')")

s.close

