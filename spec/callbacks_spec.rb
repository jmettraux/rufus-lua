
#
# Specifying rufus-lua
#
# Wed Mar 18 17:53:06 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'


describe 'callbacks' do

  before do
    @s = Rufus::Lua::State.new
  end
  after do
    @s.close
  end

  it 'should raise when no block is given' do

    lambda {
      @s.define_callback 'no_block'
    }.should.raise(RuntimeError)
  end

  it 'should work without arguments' do

    blinked = false

    @s.define_callback 'blink' do
      blinked = true
    end

    @s.eval('blink()')

    blinked.should.be.true
  end

  it 'should work with arguments' do

    message = nil

    @s.define_callback :greet do |msg|
      message = msg
    end

    @s.eval("greet('obandegozaimasu')")

    message.should.equal('obandegozaimasu')
  end

  # TODO : hash/array arguments
  # TODO : return values (ruby to lua)

end

