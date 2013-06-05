
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

      @s['unknown'].should == nil
    end
  end

  describe '#eval' do

    it 'evals true' do

      @s.eval('a = true')
      @s['a'].should == true
    end

    it 'evals false' do

      @s.eval('a = false')
      @s['a'].should == false
    end

    it 'evals strings' do

      @s.eval('a = "black adder"')
      @s['a'].should == 'black adder'
    end

    it 'evals additions' do

      @s.eval('a = 1 + 1')
      @s['a'].should == 2.0
    end

    it 'evals nested lookups' do

      @s.eval('a = { b = { c = 0 } }')
      @s.eval('_ = a.b.c')
      @s['_'].should == 0
    end

    #it 'returns the global environment' do
    #  @s['_G'].should == {}
    #end

    it 'returns numbers' do

      @s.eval('return 7').should == 7.0
    end

    it 'returns multiple values' do

      @s.eval('return 1, 2').should == [ 1.0, 2.0 ]
    end

    it 'returns false' do

      @s.eval('return false').should == false
    end

    it 'returns true' do

      @s.eval('return true').should == true
    end
  end
end

