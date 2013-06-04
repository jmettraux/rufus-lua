
#
# Specifying rufus-lua
#
# Wed Mar 11 17:09:17 JST 2009
#

require 'spec_base'


describe Rufus::Lua::State do

  before do
    @s = Rufus::Lua::State.new
  end
  after do
    @s.close
  end

  it 'should find nil when global not found' do
    @s['unknown'].should == nil
  end

  it 'should find true' do
    @s.eval('a = true')
    @s['a'].should == true
  end
  it 'should find false' do
    @s.eval('a = false')
    @s['a'].should == false
  end

  it 'should find strings' do
    @s.eval('a = "black adder"')
    @s['a'].should == 'black adder'
  end

  it 'should add' do
    @s.eval('a = 1 + 1')
    @s['a'].should == 2.0
  end

  it 'should do nested lookups' do
    @s.eval('a = { b = { c = 0 } }')
    @s.eval('_ = a.b.c')
    @s['_'].should == 0
  end

  #it 'should return the global environment' do
  #  @s['_G'].should == {}
  #end

  it 'should return numbers' do
    @s.eval('return 7').should == 7.0
  end

  it 'should return multiple values' do
    @s.eval('return 1, 2').should == [ 1.0, 2.0 ]
  end

  it 'should return false' do
    @s.eval('return false').should == false
  end

  it 'should return true' do
    @s.eval('return true').should == true
  end
end

