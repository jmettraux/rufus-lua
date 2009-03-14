
#
# Specifying rufus-lua
#
# Sat Mar 14 23:51:42 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'


describe 'Rufus::Lua::State (coroutines)' do

  before do
    @s = Rufus::Lua::State.new
  end
  after do
    @s.close
  end

  it 'should find coroutines' do
    @s.eval(
      "return coroutine.create(function (x) end)"
    ).class.should.equal(Rufus::Lua::Coroutine)
  end

  #it 'should resume coroutines' do
  #  @s.eval(%{
  #    co = coroutine.create(function (x)
  #      while true do
  #        coroutine.yield(x)
  #      end
  #    end)
  #  })
  #  @s['co'].resume(7).should.equal(7.0)
  #end

end

