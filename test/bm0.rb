
$:.unshift('lib')

require 'benchmark'

require 'rubygems'
require 'rufus/lua'


Benchmark.benchmark(' ' * 31 + Benchmark::Tms::CAPTION, 31) do |b|

  b.report('ruby') do
    1_000_000.times { |i| i }
  end

  s = Rufus::Lua::State.new
  b.report('lua') do
    s.eval('for i = 1, 1000000 do end')
  end
  s.close
end

# jmettraux@sanma ~/rufus/rufus-lua (master) $ ruby test/bm0.rb
#                                      user     system      total        real
# ruby                             0.220000   0.000000   0.220000 (  0.217909)
# lua                              0.010000   0.000000   0.010000 (  0.013667)
# jmettraux@sanma ~/rufus/rufus-lua (master) $ ruby19 test/bm0.rb
#                                      user     system      total        real
# ruby                             0.120000   0.010000   0.130000 (  0.123396)
# lua                              0.010000   0.000000   0.010000 (  0.013869)
# jmettraux@sanma ~/rufus/rufus-lua (master) $ ruby19 test/bm0.rb
#                                      user     system      total        real
# ruby                             0.110000   0.000000   0.110000 (  0.125229)
# lua                              0.020000   0.000000   0.020000 (  0.012828)

