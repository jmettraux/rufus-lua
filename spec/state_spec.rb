
#
# Specifying rufus-lua
#
# Mon Mar 16 23:38:00 JST 2009
#

require 'spec_base'


describe Rufus::Lua::State do

  it 'should not crash closing a closed State' do

    @s = Rufus::Lua::State.new
    @s.close

    lambda { @s.close }.should raise_error(RuntimeError)
  end

  it 'should load all libs by default' do

    @s = Rufus::Lua::State.new
    @s.eval('return os;').should_not == nil
    @s.close
  end

  it 'should load no libs when told so' do

    @s = Rufus::Lua::State.new(false)
    @s.eval('return os;').should == nil
    @s.close
  end

  it 'should load only specific libs when told so' do

    #@s = Rufus::Lua::State.new([ :math, :io ])
      #
      # loading io result in a PANIC (macsox at least)

    @s = Rufus::Lua::State.new([ :os, :math ])
    @s.eval('return io;').should == nil
    @s.eval('return os;').should_not == nil
    @s.close
  end
end

describe Rufus::Lua::State do

  before do
    @s = Rufus::Lua::State.new
  end
  after do
    @s.close
  end

  it 'should return nil for unbound variables' do

    @s['a'].should == nil
  end

  it 'should accept setting values directly' do

    @s['a'] = 1
    @s['a'] == 1
  end

  it 'should accept setting array values directly' do

    @s['a'] = [ true, false, %w[ alpha bravo charly ] ]
    @s['a'].to_a[0].should == true
    @s['a'].to_a[2].to_a.should == %w[ alpha bravo charly ]
  end

  it 'should accept setting hash values directly' do

    @s['a'] = { 'a' => 'alpha', 'b' => 'bravo' }
    @s['a'].to_h.should == { 'a' => 'alpha', 'b' => 'bravo' }
  end
end

