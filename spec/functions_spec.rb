
#
# Specifying rufus-lua
#
# Wed Mar 11 17:09:17 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'


describe 'Rufus::Lua::State (functions)' do

  before do
    @s = Rufus::Lua::State.new
  end
  after do
    @s.close
  end

  it 'should return Lua functions' do
    @s.eval('return function () end').class.should.equal(Rufus::Lua::Function)
  end

end

