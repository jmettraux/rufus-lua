
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
      expect(@s.eval('return os;')).not_to be nil
      @s.close
    end

    it 'loads no libs when told so' do

      @s = Rufus::Lua::State.new(false)
      expect(@s.eval('return os;')).to be nil
      @s.close
    end

    it 'loads only specific libs when told so' do

      #@s = Rufus::Lua::State.new([ :math, :io ])
        #
        # loading io result in a PANIC (macsox at least)

      @s = Rufus::Lua::State.new([ :os, :math ])
      expect(@s.eval('return io;')).to be nil
      expect(@s.eval('return os;')).not_to be nil
      @s.close
    end
  end

  describe '#close' do

    it 'does not crash when closing an already closed State' do

      @s = Rufus::Lua::State.new
      @s.close

      expect(lambda { @s.close }).to raise_error(RuntimeError)
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

      expect(@s['a']).to be nil
    end

    it 'accepts setting values directly' do

      @s['a'] = 1
      @s['a'] == 1
    end

    it 'accepts setting array values directly' do

      @s['a'] = [ true, false, %w[ alpha bravo charly ] ]
      expect(@s['a'].to_a[0]).to be true
      expect(@s['a'].to_a[2].to_a).to eq %w[ alpha bravo charly ]
    end

    it 'accepts setting hash values directly' do

      @s['a'] = { 'a' => 'alpha', 'b' => 'bravo' }
      expect(@s['a'].to_h).to eq({ 'a' => 'alpha', 'b' => 'bravo' })
    end
  end

  context 'gh-6 panic: unprotected error' do

    it 'does not happen' do

      state = Rufus::Lua::State.new(%w[ base table string math package ])
      expect(true).to be true
    end
  end
end

