
#
# Specifying rufus-lua
#
# Wed Mar 11 17:09:17 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'


describe Rufus::Lua::State do

  before do
    @s = Rufus::Lua::State.new
  end
  after do
    @s.close
  end

  it 'should find nil when global not found' do
    @s['unknown'].should.be.nil
  end

  it 'should find true' do
    @s.eval('a = true')
    @s['a'].should.be.true
  end
  it 'should find false' do
    @s.eval('a = false')
    @s['a'].should.be.false
  end

  it 'should find strings' do
    @s.eval('a = "black adder"')
    @s['a'].should.equal('black adder')
  end

  it 'should add' do
    @s.eval('a = 1 + 1')
    @s['a'].should.equal(2.0)
  end

  it 'should do nested lookups' do
    @s.eval('a = { b = { c = 0 } }')
    @s.eval('_ = a.b.c')
    @s['_'].should.equal(0)
  end

  #it 'should return the global environment' do
  #  @s['_G'].should.equal({})
  #end

  it 'should return numbers' do
    @s.eval('return 7').should.equal(7.0)
  end

  it 'should return multiple values' do
    @s.eval('return 1, 2').should.equal([ 1.0, 2.0 ])
  end
end

