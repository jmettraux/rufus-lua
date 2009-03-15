
#
# benchmarking rufus-lua
#
# Thu Mar 12 15:40:26 JST 2009
#

$:.unshift('lib')

require 'benchmark'

require 'rubygems'
require 'rufus/lua'

RUBYFIBS = Fiber.new do
  n1 = n2 = 1
  loop do
    Fiber.yield n1
    n1, n2 = n2, n1+n2
  end
end
#20.times { print RUBYFIBS.resume, ' ' }

s = %{
  co = coroutine.create(function ()
    n1 = 1; n2 = 1
    while true do
      coroutine.yield(n1)
      n1, n2 = n2, n1+n2
    end
  end)
  return co
}

LUA = Rufus::Lua::State.new
LUAFIBS = LUA.eval(s)
#20.times { print LUAFIBS.resume, ' ' }

N = 10_000
Benchmark.benchmark(' ' * 31 + Benchmark::Tms::CAPTION, 31) do |b|
  b.report('ruby') do
    N.times { RUBYFIBS.resume }
  end
  b.report('lua via ruby') do
    N.times { LUAFIBS.resume }
  end
  b.report('lua') do
    LUA.eval("for i = 0, #{N} do coroutine.resume(co) end")
  end
end

LUA.close

