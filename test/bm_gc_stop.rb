
#
# benchmarking rufus-lua
#
# Tue Mar 17 15:02:27 JST 2009
#

$:.unshift('lib')

require 'benchmark'

require 'rubygems'
require 'rufus/lua'

code = %{
  for i = 1, 10000 do
    local a = {}
    for j = 1, 2000 do
      a[#a] = j
    end
  end
}

Benchmark.benchmark(' ' * 31 + Benchmark::Tms::CAPTION, 31) do |b|

  l = Rufus::Lua::State.new

  b.report('lua (GC on)') do
    l.eval(code)
  end

  l.close

  l = Rufus::Lua::State.new
  l.gc_stop

  b.report('lua (GC off)') do
    l.eval(code)
  end

  l.close
end

