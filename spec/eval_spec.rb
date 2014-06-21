
#
# Specifying rufus-lua
#
# Wed Mar 11 17:09:17 JST 2009
#

require 'spec_base'


describe Rufus::Lua::State do

  before do
    @s = Rufus::Lua::State.new
  end
  after do
    @s.close
  end

  describe '#[]' do

    it 'returns nil for an unknown value/binding' do

      expect(@s['unknown']).to eq nil
    end
  end

  describe '#eval' do

    it 'evals true' do

      @s.eval('a = true')
      expect(@s['a']).to eq true
    end

    it 'evals false' do

      @s.eval('a = false')
      expect(@s['a']).to eq false
    end

    it 'evals strings' do

      @s.eval('a = "black adder"')
      expect(@s['a']).to eq 'black adder'
    end

    it 'evals additions' do

      @s.eval('a = 1 + 1')
      expect(@s['a']).to eq 2.0
    end

    it 'evals nested lookups' do

      @s.eval('a = { b = { c = 0 } }')
      @s.eval('_ = a.b.c')
      expect(@s['_']).to eq 0
    end

    #it 'returns the global environment' do
    #  @s['_G']).to eq {}
    #end

    it 'returns numbers' do

      expect(@s.eval('return 7')).to eq 7.0
    end

    it 'returns multiple values' do

      expect(@s.eval('return 1, 2')).to eq [ 1.0, 2.0 ]
    end

    it 'returns false' do

      expect(@s.eval('return false')).to eq false
    end

    it 'returns true' do

      expect(@s.eval('return true')).to eq true
    end

    it 'accepts a binding optional argument'

    it 'accepts a filename and a lineno optional arguments' do

      le = nil
      begin
        @s.eval('error(77)', nil, '/nada/virtual.lua', 63)
      rescue Rufus::Lua::LuaError => le
      end

      expect(le.filename).to eq('/nada/virtual.lua')
      expect(le.lineno).to eq(63)

      expect(le.original_backtrace.first).to match(/\/lua\/state\.rb:/)
      expect(le.backtrace.first).to eq('/nada/virtual.lua:63:')
    end

    context 'and errors' do

      it 'makes the file and line available' do

        le = nil
        begin
          @s.eval('error(77)')
        rescue Rufus::Lua::LuaError => le
        end

        expect(le.kind).to eq('eval:pcall')
        expect(le.msg).to eq('[string "line"]:1: 77')
        expect(le.errcode).to eq(2)

        expect(le.filename).to eq(__FILE__)
        expect(le.lineno).to eq(__LINE__ - 9)

        expect(le.original_backtrace.first).to match(/\/lua\/state\.rb:/)
        expect(le.backtrace.first).to match(/\/eval_spec\.rb:/)
      end
    end
  end
end

