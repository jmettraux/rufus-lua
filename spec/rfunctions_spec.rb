
#
# Specifying rufus-lua
#
# Wed Mar 18 17:53:06 JST 2009
#

require 'spec_base'


describe Rufus::Lua::State do

  before do
    @s = Rufus::Lua::State.new
  end
  after do
    @s.close
  end

  describe '#function' do

    it 'raises when no block is given' do

      expect(lambda {
        @s.function 'no_block'
      }).to raise_error(RuntimeError)
    end

    it 'works without arguments' do

      blinked = false

      @s.function 'blink' do
        blinked = true
      end

      @s.eval('blink()')

      expect(blinked).to eq true
    end

    it 'works with arguments' do

      message = nil

      @s.function :greet do |msg|
        message = msg
      end

      @s.eval("greet('obandegozaimasu')")

      expect(message).to eq 'obandegozaimasu'
    end

    it 'binds functions inside of Lua tables' do

      @s.eval('lib = {}')
      @s.function 'lib.myfunc' do |x|
        x + 2
      end

      expect(@s.eval("return lib.myfunc(3)")).to eq 5.0
    end

    it 'creates the top Lua table if not present' do

      @s.function 'lib.myfunc' do |x|
        x + 2
      end

      expect(@s.eval("return lib.myfunc(3)")).to eq 5.0
    end

    it 'only creates the top table (not intermediary tables)' do

      expect(lambda {
        @s.function('lib.toto.myfunc') { |x| x + 2 }
      }).to raise_error(ArgumentError)
    end
  end

  describe 'calling a Ruby function from Lua' do

    it 'may return a single value' do

      @s.function :greet do
        'hello !'
      end

      expect(@s.eval('return greet()')).to eq 'hello !'
    end

    it 'may return multiple values' do

      @s.function :compute do
        [ 'a', true, 1 ]
      end

      expect(@s.eval('return compute()').to_a).to eq [ 'a', true, 1.0 ]
    end

    it 'may return tables' do

      @s.function :compute do
        { 'a' => 'alpha', 'z' => 'zebra' }
      end

      expect(@s.eval('return compute()').to_h).to eq(
        { 'a' => 'alpha', 'z' => 'zebra' })
    end

    it 'may return tables (with nested arrays)' do

      @s.function :compute do
        { 'a' => 'alpha', 'z' => [ 1, 2, 3 ] }
      end

      expect(@s.eval('return compute()').to_h['z'].to_a).to eq [ 1.0, 2.0, 3.0 ]
    end

    it 'accepts hashes as arguments' do

      @s.function :to_json do |h|
        "{" + h.collect { |k, v| "#{k}:\"#{v}\"" }.join(",") + "}"
      end

      expect(@s.eval(
        "return to_json({ a = 'ALPHA', b = 'BRAVO' })"
      )).to eq(
        '{a:"ALPHA",b:"BRAVO"}'
      )
    end

    it 'accepts arrays as arguments' do

      @s.function :do_join do |a|
        a.to_a.join(', ')
      end

      expect(@s.eval(
        "return do_join({ 'alice', 'bob', 'charly' })"
      )).to eq(
        'alice, bob, charly'
      )
    end

    it 'raise exceptions (Ruby -> Lua -> Ruby and back)' do

      @s.function :do_fail do
        raise "fail!"
      end

      expect(lambda {
        @s.eval("return do_fail()")
      }).to raise_error(RuntimeError)
    end

    it 'counts the animals correctly' do

      @s.function 'key_up' do |table|
        table.inject({}) do |h, (k, v)|
          h[k.to_s.upcase] = v; h
        end
      end

      expect(@s.eval(%{
        local table = {}
        table['CoW'] = 2
        table['pigs'] = 3
        table['DUCKS'] = 'none'
        return key_up(table)
      }).to_h).to eq(
        { 'COW' => 2.0, 'DUCKS' => 'none', 'PIGS' => 3.0 }
      )
    end

    it 'returns Ruby arrays as Lua tables' do

      @s.function :get_data do |msg|
        %w[ one two three ]
      end

      @s.eval('data = get_data()')

      expect(@s['data'].to_a).to eq %w[ one two three ]
      expect(@s.eval('return type(data)')).to eq('table')
    end

    it 'return properly indexed Lua tables' do

      @s.function :get_data do |msg|
        %w[ one two three ]
      end

      @s.eval('data = get_data()')

      expect(@s.eval('return data[0]')).to eq nil
      expect(@s.eval('return data[1]')).to eq 'one'
    end

    it 'accepts more than 1 arg and order the args correctly' do

      @s.function 'myfunc' do |a, b, c|
        "#{a}_#{b}_#{c}"
      end

      expect(@s.eval("return myfunc(1, 2, 3)")).to eq '1.0_2.0_3.0'
    end

    it 'accepts optional arguments' do

      @s.function 'myfunc' do |a, b, c|
        "#{a}_#{b}_#{c}"
      end

      expect(@s.eval("return myfunc(1)")).to eq '1.0__'
    end

    it 'is ok when there are too many args' do

      @s.function 'myfunc' do |a, b|
        "#{a}_#{b}"
      end

      expect(@s.eval("return myfunc(1, 2, 3)")).to eq '1.0_2.0'
    end

    it 'passes Float arguments correctly' do

      @s.function 'myfunc' do |a|
        "#{a.class} #{a}"
      end

      expect(@s.eval("return myfunc(3.14)")).to eq 'Float 3.14'
    end

    it 'preserves arguments' do

      @s.function 'check_types' do |t, s, f, h, a|

        #p [ t, s, f, h, a ]

        (t.is_a?(TrueClass) &&
         s.is_a?(String) &&
         f.is_a?(Float) &&
         h.is_a?(Rufus::Lua::Table) &&
         a.is_a?(Rufus::Lua::Table))
      end

      expect(@s.eval(
        "return check_types(true, 'foobar', 3.13, {a='ay',b='bee'}, {'one','two','three'})"
      )).to eq true
    end

    it 'honours to_ruby=true' do

      @s.function 'check_types', :to_ruby => true do |t, s, f, h, a|

        #p [ t, s, f, h, a ]

        (t.is_a?(TrueClass) &&
         s.is_a?(String) &&
         f.is_a?(Float) &&
         h.is_a?(Hash) &&
         a.is_a?(Array))
      end

      expect(@s.eval(
        "return check_types(true, 'foobar', 3.13, {a='ay',b='bee'}, {'one','two','three'})"
      )).to eq true
    end

    it 'protects callbacks from GC' do

      @s.function 'myfunc' do |a|
      end

      expect(@s.instance_variable_get(:@callbacks).size).to eq 1
    end
  end
end

