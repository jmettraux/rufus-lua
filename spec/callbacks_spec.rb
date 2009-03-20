
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

  it 'should return tables (with nested array)' do
    @s.function :compute do
      { 'a' => 'alpha', 'z' => [ 1, 2, 3 ] }
    end
    @s.eval('return compute()').to_h['z'].to_a.should.equal(
      [ 1.0, 2.0, 3.0 ]
    )
  end

  it 'should accept hashes as arguments' do

    @s.function :to_json do |h|
      "{" + h.collect { |k, v| "#{k}:\"#{v}\"" }.join(",") + "}"
    end
    @s.eval(
      "return to_json({ a = 'ALPHA', b = 'BRAVO' })"
    ).should.equal(
      '{a:"ALPHA",b:"BRAVO"}'
    )
  end

  it 'should accept arrays as arguments' do

    @s.function :do_join do |a|
      a.to_a.join(', ')
    end
    @s.eval(
      "return do_join({ 'alice', 'bob', 'charly' })"
    ).should.equal(
      'alice, bob, charly'
    )
  end

  it 'should raise exceptions' do

    @s.function :do_fail do
      raise "fail!"
    end
    lambda {
      @s.eval("return do_fail()")
    }.should.raise(RuntimeError)
  end

  it 'should count the animals correctly' do

    @s.function 'key_up' do |table|
      table.inject({}) do |h, (k, v)|
        h[k.to_s.upcase] = v; h
      end
    end

    @s.eval(%{
      local table = {}
      table['CoW'] = 2
      table['pigs'] = 3
      table['DUCKS'] = 'none'
      return key_up(table)
    }).to_h.should.equal(
      { 'COW' => 2.0, 'DUCKS' => 'none', 'PIGS' => 3.0 }
    )
  end

end

