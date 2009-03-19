
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
      @s.function 'no_block'
    }.should.raise(RuntimeError)
  end

  it 'should work without arguments' do

    blinked = false

    @s.function 'blink' do
      blinked = true
    end

    @s.eval('blink()')

    blinked.should.be.true
  end

  it 'should work with arguments' do

    message = nil

    @s.function :greet do |msg|
      message = msg
    end

    @s.eval("greet('obandegozaimasu')")

    message.should.equal('obandegozaimasu')
  end

  it 'should return a single value' do

    @s.function :greet do
      'hello !'
    end
    @s.eval('return greet()').should.equal('hello !')
  end

  it 'should return multiple values' do

    @s.function :compute do
      [ 'a', true, 1 ]
    end
    @s.eval('return compute()').should.equal([ 'a', true, 1.0 ])
  end

  it 'should return tables' do

    @s.function :compute do
      { 'a' => 'alpha', 'z' => 'zebra' }
    end
    @s.eval('return compute()').to_h.should.equal(
      { 'a' => 'alpha', 'z' => 'zebra' }
    )
  end

  #it 'should return tables (with nested array)' do
  #  @s.function :compute do
  #    { 'a' => 'alpha', 'z' => [ 1, 2, 3 ] }
  #  end
  #  @s.eval('return compute()').to_h.should.equal(
  #    ''
  #  )
  #end

  # TODO : errors !
  # TODO : hash/array arguments
  # TODO : return values (ruby to lua)

end

