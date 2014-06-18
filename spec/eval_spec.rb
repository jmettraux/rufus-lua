
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
  end
end

