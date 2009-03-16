
#
# Specifying rufus-lua
#
# Mon Mar 16 23:38:00 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'


describe 'Rufus::Lua::State' do

  it 'should not crash closing a closed State' do

    @s = Rufus::Lua::State.new
    @s.close

    should.raise(RuntimeError) { @s.close }
  end
end
