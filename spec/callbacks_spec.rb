
#
# Specifying rufus-lua
#
# Wed Mar 18 17:53:06 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'


describe 'Rufus::Lua::State (functions)' do

  before do
    @s = Rufus::Lua::State.new
  end
  after do
    @s.close
  end

  it 'should accept Ruby callbacks' do

    blinked = false

    @s.define_ruby_function 'blink' do
      blinked = true
    end

    @s.eval('blink()')

    blinked.should.be.true
  end

end

