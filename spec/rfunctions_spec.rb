
#
# Specifying rufus-lua
#
# Wed Mar 18 17:53:06 JST 2009
#

require 'spec_base'


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
    }.should raise_error(RuntimeError)
  end

  it 'should work without arguments' do

    blinked = false

    @s.function 'blink' do
      blinked = true
    end

    @s.eval('blink()')

    blinked.should == true
  end

  it 'should work with arguments' do

    message = nil

    @s.function :greet do |msg|
      message = msg
    end

    @s.eval("greet('obandegozaimasu')")

    message.should == 'obandegozaimasu'
  end

  it 'should return a single value' do

    @s.function :greet do
      'hello !'
    end
    @s.eval('return greet()').should == 'hello !'
  end

  it 'should return multiple values' do

    @s.function :compute do
      [ 'a', true, 1 ]
    end
    @s.eval('return compute()').to_a.should == [ 'a', true, 1.0 ]
  end

  it 'should return tables' do

    @s.function :compute do
      { 'a' => 'alpha', 'z' => 'zebra' }
    end

    @s.eval('return compute()').to_h.should ==
      { 'a' => 'alpha', 'z' => 'zebra' }
  end

  it 'should return tables (with nested array)' do

    @s.function :compute do
      { 'a' => 'alpha', 'z' => [ 1, 2, 3 ] }
    end
    @s.eval('return compute()').to_h['z'].to_a.should == [ 1.0, 2.0, 3.0 ]
  end

  it 'should accept hashes as arguments' do

    @s.function :to_json do |h|
      "{" + h.collect { |k, v| "#{k}:\"#{v}\"" }.join(",") + "}"
    end

    @s.eval(
      "return to_json({ a = 'ALPHA', b = 'BRAVO' })"
    ).should ==
      '{a:"ALPHA",b:"BRAVO"}'
  end

  it 'should accept arrays as arguments' do

    @s.function :do_join do |a|
      a.to_a.join(', ')
    end

    @s.eval(
      "return do_join({ 'alice', 'bob', 'charly' })"
    ).should ==
      'alice, bob, charly'
  end

  it 'should raise exceptions' do

    @s.function :do_fail do
      raise "fail!"
    end

    lambda {
      @s.eval("return do_fail()")
    }.should raise_error(RuntimeError)
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
    }).to_h.should ==
      { 'COW' => 2.0, 'DUCKS' => 'none', 'PIGS' => 3.0 }
  end

  it 'should bind functions inside of tables' do

    @s.eval('lib = {}')
    @s.function 'lib.myfunc' do |x|
      x + 2
    end

    @s.eval("return lib.myfunc(3)").should == 5.0
  end

  it 'should create the top table if not present' do

    @s.function 'lib.myfunc' do |x|
      x + 2
    end

    @s.eval("return lib.myfunc(3)").should == 5.0
  end

  it 'should only create the top table' do

    lambda {
      @s.function('lib.toto.myfunc') { |x| x + 2 }
    }.should raise_error(ArgumentError)
  end

  it 'should return ruby arrays as lua tables' do

    @s.function :get_data do |msg|
      %w[ one two three ]
    end

    @s.eval('data = get_data()')

    @s['data'].to_a.should == %w[ one two three ]
    @s.eval('return type(data)').should == 'table'
  end

  it 'should return lua tables that are properly indexed' do

    @s.function :get_data do |msg|
      %w[ one two three ]
    end

    @s.eval('data = get_data()')

    @s.eval('return data[0]').should == nil
    @s.eval('return data[1]').should == 'one'
  end

  it 'should accept more than 1 arg and order them correctly' do

    @s.function 'myfunc' do |a, b, c|
      "#{a}_#{b}_#{c}"
    end

    @s.eval("return myfunc(1, 2, 3)").should == '1.0_2.0_3.0'
  end

  it 'should accept optional arguments' do

    @s.function 'myfunc' do |a, b, c|
      "#{a}_#{b}_#{c}"
    end

    @s.eval("return myfunc(1)").should == '1.0__'
  end

  it 'should be ok when there are too many args' do

    @s.function 'myfunc' do |a, b|
      "#{a}_#{b}"
    end

    @s.eval("return myfunc(1, 2, 3)").should == '1.0_2.0'
  end

  it 'should pass Float arguments correctly' do

    @s.function 'myfunc' do |a|
      "#{a.class} #{a}"
    end

    @s.eval("return myfunc(3.14)").should == 'Float 3.14'
  end

  it 'should preserve arguments' do

    @s.function 'check_types' do |t, s, f, h, a|

      #p [ t, s, f, h, a ]

      (t.is_a?(TrueClass) &&
       s.is_a?(String) &&
       f.is_a?(Float) &&
       h.is_a?(Rufus::Lua::Table) &&
       a.is_a?(Rufus::Lua::Table))
    end

    @s.eval(
      "return check_types(true, 'foobar', 3.13, {a='ay',b='bee'}, {'one','two','three'})"
    ).should == true
  end

  it 'should honour to_ruby=true' do

    @s.function 'check_types', :to_ruby => true do |t, s, f, h, a|

      #p [ t, s, f, h, a ]

      (t.is_a?(TrueClass) &&
       s.is_a?(String) &&
       f.is_a?(Float) &&
       h.is_a?(Hash) &&
       a.is_a?(Array))
    end

    @s.eval(
      "return check_types(true, 'foobar', 3.13, {a='ay',b='bee'}, {'one','two','three'})"
    ).should == true
  end

  it 'should preserve callbacks from GC' do

    @s.function 'myfunc' do |a|
    end

    @s.instance_variable_get(:@callbacks).size.should == 1
  end
end

