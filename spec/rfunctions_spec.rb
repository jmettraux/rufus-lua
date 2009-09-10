
#
# Specifying rufus-lua
#
# Wed Mar 18 17:53:06 JST 2009
#

require File.dirname(__FILE__) + '/spec_base'


describe 'Ruby functions bound in Lua (callbacks)' do

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
    @s.eval('return compute()').to_a.should.equal([ 'a', true, 1.0 ])
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

  it 'should bind functions inside of tables' do

    @s.eval('lib = {}')
    @s.function 'lib.myfunc' do |x|
      x + 2
    end

    @s.eval("return lib.myfunc(3)").should.equal(5.0)
  end

  it 'should create the top table if not present' do

    @s.function 'lib.myfunc' do |x|
      x + 2
    end
    @s.eval("return lib.myfunc(3)").should.equal(5.0)
  end

  it 'should only create the top table' do

    lambda {
      @s.function('lib.toto.myfunc') { |x| x + 2 }
    }.should.raise(ArgumentError)
  end

  it 'should return ruby arrays as lua tables' do

    @s.function :get_data do |msg|
      %w[ one two three ]
    end

    @s.eval('data = get_data()')

    @s['data'].to_a.should.equal(%w[ one two three ])
    @s.eval('return type(data)').should.equal('table')
  end

  it 'should return lua tables that are properly indexed' do

    @s.function :get_data do |msg|
      %w[ one two three ]
    end

    @s.eval('data = get_data()')

    @s.eval('return data[0]').should.be.nil
    @s.eval('return data[1]').should.equal('one')
  end

  it 'should accept more than 1 arg and order them correctly' do

    @s.function 'myfunc' do |a, b, c|
      "#{a}_#{b}_#{c}"
    end

    @s.eval("return myfunc(1, 2, 3)").should.equal('1.0_2.0_3.0')
  end

  it 'should accept optional arguments' do

    @s.function 'myfunc' do |a, b, c|
      "#{a}_#{b}_#{c}"
    end

    @s.eval("return myfunc(1)").should.equal('1.0__')
  end

  it 'should be ok when there are too many args' do

    @s.function 'myfunc' do |a, b|
      "#{a}_#{b}"
    end

    @s.eval("return myfunc(1, 2, 3)").should.equal('1.0_2.0')
  end

  it 'should pass Float arguments correctly' do

    @s.function 'myfunc' do |a|
      "#{a.class} #{a}"
    end

    @s.eval("return myfunc(3.14)").should.equal('Float 3.14')
  end

  it 'should preserve arguments' do

    @s.function 'check_types' do |t, s, f, h, a|

      #p [ t, s, f, h.to_h, a ]

      (t.is_a?(TrueClass) &&
       s.is_a?(String) &&
       f.is_a?(Float) &&
       h.is_a?(Rufus::Lua::Table) &&
       a.is_a?(Rufus::Lua::Table))
    end

    @s.eval("return check_types(true, 'foobar', 3.13, {a='ay',b='bee'}, {'one','two','three'})").should.equal(true)
  end
end

