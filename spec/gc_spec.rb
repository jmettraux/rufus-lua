
#
# Specifying rufus-lua
#
# Mon Mar 16 23:07:49 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'


describe 'Rufus::Lua::State (gc)' do

  it 'should call functions with arguments' do

    @s = Rufus::Lua::State.new
    @s.close

    lambda {
      @s.gc_collect!
    }.should.raise(RuntimeError)
  end

end

