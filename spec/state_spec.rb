
#
# Specifying rufus-lua
#
# Mon Mar 16 23:38:00 JST 2009
#

require 'spec_base'


describe Rufus::Lua::State do

  describe '#new' do

    it 'loads all libs by default' do

      @s = Rufus::Lua::State.new
      @s.eval('return os;').should_not == nil
      @s.close
    end

    it 'loads no libs when told so' do

      @s = Rufus::Lua::State.new(false)
      @s.eval('return os;').should == nil
      @s.close
    end

    it 'loads only specific libs when told so' do

      #@s = Rufus::Lua::State.new([ :math, :io ])
        #
        # loading io result in a PANIC (macsox at least)

      @s = Rufus::Lua::State.new([ :os, :math ])
      @s.eval('return io;').should == nil
      @s.eval('return os;').should_not == nil
      @s.close
    end
  end

  describe '#close' do

    it 'does not crash when closing an already closed State' do

      @s = Rufus::Lua::State.new
      @s.close

      lambda { @s.close }.should raise_error(RuntimeError)
    end
  end

  describe '#[]' do

    before do
      @s = Rufus::Lua::State.new
    end
    after do
      @s.close
    end

    it 'return nils for unbound variables' do

      @s['a'].should == nil
    end

    it 'accepts setting values directly' do

      @s['a'] = 1
      @s['a'] == 1
    end

    it 'accepts setting array values directly' do

      @s['a'] = [ true, false, %w[ alpha bravo charly ] ]
      @s['a'].to_a[0].should == true
      @s['a'].to_a[2].to_a.should == %w[ alpha bravo charly ]
    end

    it 'accepts setting hash values directly' do

      @s['a'] = { 'a' => 'alpha', 'b' => 'bravo' }
      @s['a'].to_h.should == { 'a' => 'alpha', 'b' => 'bravo' }
    end
  end
end

