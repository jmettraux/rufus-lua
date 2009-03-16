
#
# Specifying rufus-lua
#
# Fri Mar 13 23:42:29 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'


describe 'Rufus::Lua::State (tables)' do

  before do
    @s = Rufus::Lua::State.new
  end
  after do
    @s.close
  end

  it 'should find a hash' do
    @s.eval('h = { a = "b", c = 2, 4 }')
    @s['h'].to_h.should.equal({ 'a' => 'b', 'c' => 2.0, 1.0 => 4.0 })
  end

  it 'should turn a hash into an array' do
    @s.eval('a = { "a", "b", "c" }')
    @s['a'].to_h.should.equal({ 1.0 => 'a', 2.0 => 'b', 3.0 => 'c' })
    @s['a'].to_a.should.equal(%w{ a b c })
  end

  it 'should do nested lookups (2)' do
    @s.eval('a = { b = { c = 0 } }')
    @s['a.b.c'].should.equal(0)
  end

  it 'should return Lua tables' do
    @s.eval('return {}').class.should.equal(Rufus::Lua::Table)
  end

  it 'should return turn Lua tables into Ruby hashes' do
    @s.eval('return {}').to_h.should.equal({})
  end

  it 'should free tables' do

    t = @s.eval('t = {}; return t')
    t.free

    t.ref.should.be.nil
    lambda { t.to_h }.should.raise(Rufus::Lua::LuaError)
  end

  it 'should index tables' do

    t = @s.eval("return { a = 'A' }")
    t['a'].should.equal('A')
    t['b'].should.be.nil
  end

  it 'should iterate on tables' do
    #t = @s.eval("return { a = 'A', b = 'B', c = 3, d = 3.1 }")
    t = @s.eval("return { a = 'A', b = 'B', c = 3 }")
    t.values.sort { |a, b| a.to_s <=> b.to_s }.should.equal([ 3.0, 'A', 'B' ])
    t.keys.sort.should.equal([ 'a', 'b', 'c' ])
  end

  it 'should provide keys and values for tables' do
    t = @s.eval("return { a = 'A', b = 'B', c = 3 }")
    t.collect { |k, v| v }.size.should.equal(3)
  end
end

