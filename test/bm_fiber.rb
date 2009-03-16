
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
    local n1 = 1
    local n2 = 1
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


# jmettraux@sanma ~/rufus/rufus-lua (master) $ ruby19 test/bm_fiber.rb
#                                      user     system      total        real
# ruby                             0.050000   0.010000   0.060000 (  0.054605)
# lua via ruby                     0.180000   0.000000   0.180000 (  0.189010)
# lua                              0.010000   0.000000   0.010000 (  0.005543)
# jmettraux@sanma ~/rufus/rufus-lua (master) $ ruby19 test/bm_fiber.rb
#                                      user     system      total        real
# ruby                             0.050000   0.000000   0.050000 (  0.051531)
# lua via ruby                     0.180000   0.010000   0.190000 (  0.194944)
# lua                              0.010000   0.000000   0.010000 (  0.006325)
# jmettraux@sanma ~/rufus/rufus-lua (master) $ ruby19 test/bm_fiber.rb
#                                      user     system      total        real
# ruby                             0.050000   0.010000   0.060000 (  0.052032)
# lua via ruby                     0.180000   0.000000   0.180000 (  0.195411)
# lua                              0.010000   0.000000   0.010000 (  0.006394)
# jmettraux@sanma ~/rufus/rufus-lua (master) $ ruby19 test/bm_fiber.rb
#                                      user     system      total        real
# ruby                             0.050000   0.010000   0.060000 (  0.054892)
# lua via ruby                     0.180000   0.000000   0.180000 (  0.267880)
# lua                              0.000000   0.000000   0.000000 (  0.005865)

